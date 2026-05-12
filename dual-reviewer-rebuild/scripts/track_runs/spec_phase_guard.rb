# frozen_string_literal: true

require "json"
require "pathname"

module DualReviewer
  module TrackRuns
    class SpecPhaseGuard
      class GuardError < StandardError; end

      attr_reader :repo_root

      def initialize(repo_root:)
        @repo_root = Pathname(repo_root).expand_path
      end

      def validate_spec!(spec_json_path:)
        path = expand_path(spec_json_path)
        payload = JSON.parse(path.read)
        validate_payload!(payload: payload, spec_json_path: path)
      end

      def strict_opt_in_spec_paths
        workspace_roots.flat_map do |root|
          Dir[root.join(".kiro/specs/*/spec.json").to_s]
        end
          .uniq
          .map { |path| Pathname(path) }
          .select { |path| strict_guard_enabled_for_spec_path?(path) }
      end

      def strict_guard_enabled_for_spec_path?(spec_json_path)
        payload = JSON.parse(expand_path(spec_json_path).read)
        strict_guard_enabled_for_payload?(payload)
      end

      def strict_guard_enabled_for_payload?(payload)
        payload.dig("custom", "spec_phase_guard") == "strict"
      end

      def assert_phase_entry_allowed!(phase:, refs:)
        spec_paths = spec_paths_from_refs(refs)
        raise GuardError, "no spec.json resolved from refs: #{refs.join(', ')}" if spec_paths.empty?

        spec_paths.each do |spec_path|
          payload = JSON.parse(spec_path.read)
          next unless strict_guard_enabled_for_payload?(payload)

          validate_payload!(payload: payload, spec_json_path: spec_path)

          case phase
          when "design"
            next if approved?(payload, "requirements")

            raise GuardError, "#{relative(spec_path)} blocks design entry: requirements approval is required"
          when "tasks"
            next if approved?(payload, "design")

            raise GuardError, "#{relative(spec_path)} blocks tasks entry: design approval is required"
          when "implementation"
            next if approved?(payload, "tasks") && payload["ready_for_implementation"] == true

            raise GuardError, "#{relative(spec_path)} blocks implementation entry: tasks approval and ready_for_implementation=true are required"
          else
            raise GuardError, "unsupported phase guard target: #{phase}"
          end
        end
      end

      private

      def validate_payload!(payload:, spec_json_path:)
        approvals = payload.fetch("approvals")
        phase = payload.fetch("phase")
        errors = []
        intent_fixed_phase = phase == "intent-fixed"
        intent_generated = generated?(approvals, "intent")
        intent_approved = approved?(payload, "intent")

        req_generated = generated?(approvals, "requirements")
        req_approved = approved?(payload, "requirements")
        design_generated = generated?(approvals, "design")
        design_approved = approved?(payload, "design")
        tasks_generated = generated?(approvals, "tasks")
        tasks_approved = approved?(payload, "tasks")
        ready_for_implementation = payload["ready_for_implementation"] == true

        errors << "requirements.generated must be true" unless req_generated || intent_fixed_phase
        errors << "design.generated requires requirements.approved=true" if design_generated && !req_approved
        errors << "design.approved requires design.generated=true" if design_approved && !design_generated
        errors << "design.approved requires requirements.approved=true" if design_approved && !req_approved
        errors << "tasks.generated requires design.approved=true" if tasks_generated && !design_approved
        errors << "tasks.approved requires tasks.generated=true" if tasks_approved && !tasks_generated
        errors << "tasks.approved requires design.approved=true" if tasks_approved && !design_approved
        errors << "ready_for_implementation requires tasks.approved=true" if ready_for_implementation && !tasks_approved

        case phase
        when "intent-fixed"
          errors << "phase intent-fixed requires intent.generated=true" unless intent_generated
          errors << "phase intent-fixed requires intent.approved=true" unless intent_approved
          errors << "phase intent-fixed forbids requirements.generated=true" if req_generated
          errors << "phase intent-fixed forbids design.generated=true" if design_generated
          errors << "phase intent-fixed forbids tasks.generated=true" if tasks_generated
        when "requirements-generated"
          errors << "phase requirements-generated requires requirements.approved=false" if req_approved
          errors << "phase requirements-generated forbids design.generated=true" if design_generated
          errors << "phase requirements-generated forbids tasks.generated=true" if tasks_generated
        when "requirements-approved"
          errors << "phase requirements-approved requires requirements.approved=true" unless req_approved
          errors << "phase requirements-approved forbids design.generated=true" if design_generated
          errors << "phase requirements-approved forbids tasks.generated=true" if tasks_generated
        when "design-generated"
          errors << "phase design-generated requires requirements.approved=true" unless req_approved
          errors << "phase design-generated requires design.generated=true" unless design_generated
          errors << "phase design-generated requires design.approved=false" if design_approved
          errors << "phase design-generated forbids tasks.generated=true" if tasks_generated
        when "design-approved"
          errors << "phase design-approved requires design.approved=true" unless design_approved
          errors << "phase design-approved forbids tasks.generated=true" if tasks_generated
        when "tasks-generated"
          errors << "phase tasks-generated requires tasks.generated=true" unless tasks_generated
          errors << "phase tasks-generated requires tasks.approved=false" if tasks_approved
        when "tasks-approved"
          errors << "phase tasks-approved requires tasks.approved=true" unless tasks_approved
        when "implementation-completed"
          errors << "phase implementation-completed requires tasks.approved=true" unless tasks_approved
          errors << "phase implementation-completed requires ready_for_implementation=true" unless ready_for_implementation
        end

        return if errors.empty?

        raise GuardError, "#{relative(spec_json_path)} violates spec phase guard: #{errors.join('; ')}"
      end

      def spec_paths_from_refs(refs)
        refs.map { |ref| resolve_spec_json_path(ref) }.compact.uniq
      end

      def resolve_spec_json_path(ref)
        path = expand_path(ref)
        current = path.file? ? path.dirname : path

        loop do
          spec_path = current.join("spec.json")
          return spec_path if spec_path.file?
          break if current == current.parent

          current = current.parent
        end

        nil
      end

      def expand_path(pathish)
        path = Pathname(pathish)
        return path if path.absolute?

        workspace_roots.each do |root|
          candidate = root.join(path)
          return candidate if candidate.exist?
        end

        repo_root.join(path)
      end

      def generated?(approvals, key)
        approvals.fetch(key, {}).fetch("generated", false) == true
      end

      def approved?(payload, key)
        payload.fetch("approvals").fetch(key, {}).fetch("approved", false) == true
      end

      def relative(path)
        absolute = expand_path(path)
        workspace_roots.each do |root|
          return absolute.relative_path_from(root).to_s if absolute.to_s.start_with?(root.to_s)
        end

        expand_path(path).to_s
      rescue StandardError
        expand_path(path).to_s
      end

      def workspace_roots
        @workspace_roots ||= begin
          roots = [repo_root]
          parent = repo_root.parent
          roots << parent if parent.join(".kiro/specs").directory?
          roots.uniq
        end
      end
    end
  end
end
