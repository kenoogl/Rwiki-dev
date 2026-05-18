#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"
require "json"
require "optparse"
require "pathname"
require "time"

module DualReviewer
  module Scripts
    class ReferenceFreeCaseBootstrap
      attr_reader :repo_root, :slug, :canonical_source, :intent_source, :tracks, :force

      def initialize(repo_root:, slug:, canonical_source:, intent_source:, tracks:, force:)
        @repo_root = Pathname(repo_root).expand_path
        @slug = slug
        @canonical_source = canonical_source
        @intent_source = intent_source
        @tracks = tracks
        @force = force
      end

      def run
        ensure_target_paths!
        FileUtils.mkdir_p(spec_dir)
        FileUtils.mkdir_p(methodology_dir)

        write_file(intent_path, rendered_intent)
        write_file(spec_json_path, JSON.pretty_generate(spec_json_payload) + "\n")
        write_file(case_workflow_overlay_path, rendered_case_workflow_overlay)
        write_file(active_worklist_path, rendered_active_worklist)
        write_file(workflow_path_path, rendered_workflow_path)

        puts "bootstrapped reference-free case: #{slug}"
        puts "intent: #{intent_path}"
        puts "state: #{spec_json_path}"
        puts "overlay: #{case_workflow_overlay_path}"
        puts "active worklist: #{active_worklist_path}"
        puts "workflow path: #{workflow_path_path}"
      end

      private

      def timestamp
        @timestamp ||= Time.now.iso8601
      end

      def today
        @today ||= Time.now.strftime("%Y-%m-%d")
      end

      def spec_dir
        repo_root.join(".kiro/specs/#{slug}-spec")
      end

      def methodology_dir
        repo_root.join(".kiro/methodology/dual-reviewer-spec-driven-paper")
      end

      def intent_path
        spec_dir.join("intent.md")
      end

      def spec_json_path
        spec_dir.join("spec.json")
      end

      def case_workflow_overlay_path
        methodology_dir.join("#{slug}-case-workflow-overlay.md")
      end

      def active_worklist_path
        methodology_dir.join("#{slug}-active-worklist.md")
      end

      def workflow_path_path
        methodology_dir.join("#{slug}-workflow-path.md")
      end

      def ensure_target_paths!
        [intent_path, spec_json_path, case_workflow_overlay_path, active_worklist_path, workflow_path_path].each do |path|
          next if force || !path.exist?

          raise ArgumentError, "target already exists: #{path}"
        end
      end

      def write_file(path, content)
        path.write(content)
      end

      def spec_json_payload
        {
          "feature_name" => "#{slug}-spec",
          "created_at" => timestamp,
          "updated_at" => timestamp,
          "language" => "ja",
          "phase" => "intent-fixed",
          "approvals" => {
            "intent" => { "generated" => true, "approved" => true },
            "requirements" => { "generated" => false, "approved" => false },
            "design" => { "generated" => false, "approved" => false },
            "tasks" => { "generated" => false, "approved" => false },
            "review_acquisition" => { "generated" => false, "approved" => false },
            "implementation" => { "generated" => false, "approved" => false }
          },
          "ready_for_implementation" => false,
          "ready_for_review_acquisition" => false,
          "custom" => {
            "case_slug" => slug,
            "bootstrap_mode" => "reference-free",
            "canonical_source" => canonical_source,
            "intent_source" => intent_source,
            "tracks" => tracks,
            "spec_phase_guard" => "strict",
            "active_feature_count" => 0
          }
        }
      end

      def rendered_intent
        <<~MARKDOWN
          # #{slug} intent

          _作成: #{today}_  
          _status: bootstrap intent fixed v0.1_  
          _purpose: reference-free case bootstrap のために canonical source と current intent を固定する_

          ---

          ## 1. canonical source

          - intent source:
            - `#{intent_source}`
          - canonical source:
            - `#{canonical_source}`

          ## 2. current understanding

          - goal:
            - `<この case で実現したいことを書く>`
          - non-goal:
            - `<この case で意図的に扱わないことを書く>`
          - failure to avoid:
            - `<避けたい失敗を plain language で書く>`

          ## 3. bootstrap note

          - bootstrap mode:
            - `reference-free`
          - next action:
            - active feature set を提案し、human `intent gate` に出す
          - default heuristic profile policy:
            - intent/spec/implementation ともに minimal template から始め、必要なときだけ case 固有 rule を追加する
        MARKDOWN
      end

      def rendered_case_workflow_overlay
        <<~MARKDOWN
          # #{slug} case workflow overlay

          _status: bootstrap overlay_  
          _purpose: generic workflow に対する #{slug} case 固有差分だけを短く固定する_

          ---

          ## 1. Role

          この文書は generic workflow の代替ではない。  
          手順の正本は [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md:1) とする。

          ## 2. Case Identity

          - case id:
            - `#{slug}`
          - core note:
            - `<core-case-#{slug}.md を後で追加する>`
          - canonical source:
            - `#{canonical_source}`
          - umbrella state:
            - [spec.json](#{spec_json_path}:1)

          ## 3. Active Feature Set

          - active features:
            - `<intent gate で確定する>`

          ## 4. Dependency Order

          - order:
            1. `<intent gate で確定する>`

          ## 5. Approval Model

          - human gates:
            - `requirements | design | tasks | implementation | review acquisition(optional)`
          - fixed inputs:
            - `#{intent_source}`
            - `#{canonical_source}`

          ## 6. Special Stop Conditions

          - stop when:
            - canonical source interpretation forks
            - active feature split changes scope
            - gate closure basis is missing

          ## 7. Optional Extensions

          - uses review acquisition:
            - `<yes | no>`
          - uses behavioral appendix boundary:
            - `<yes | no>`

          ## 8. Primary Working Artifacts

          - workflow trace:
            - [#{workflow_path_path.basename}](#{workflow_path_path}:1)
          - current control board:
            - [#{active_worklist_path.basename}](#{active_worklist_path}:1)
          - main evidence bundle:
            - `<later>`
        MARKDOWN
      end

      def rendered_active_worklist
        <<~MARKDOWN
          # #{slug} active worklist

          _status: bootstrap in progress_  
          _purpose: #{slug} case の current control board_

          ---

          ## 1. Role

          この文書の役割は、**今この case で何を実行中か**を固定することに限る。

          ## 2. Authoritative Refs

          - workflow:
            - [HUMAN_WORKFLOW.md](/Users/Daily/Development/Rwiki-dev/dual-reviewer-rebuild/operations/HUMAN_WORKFLOW.md:1)
          - case bootstrap guide:
            - [reference-free-case-bootstrap-guide.md](/Users/Daily/Development/Rwiki-dev/.kiro/methodology/dual-reviewer-spec-driven-paper/reference-free-case-bootstrap-guide.md:1)
          - overlay:
            - [#{case_workflow_overlay_path.basename}](#{case_workflow_overlay_path}:1)
          - state:
            - [spec.json](#{spec_json_path}:1)

          ## 3. Current Workflow Step

          - current phase:
            - `intent`
          - current artifact type:
            - `intent.md`
          - current target set:
            - `active feature proposal`

          ## 4. Current Blocker

          - blocker:
            - `none`

          ## 5. Current Action

          - action:
            - source docs を読み、active feature set と dependency order を提案する

          ## 6. Exit Condition

          - exit:
            - human `intent gate` に出せる初回 gate input が揃っていること

          ## 7. Working Artifacts

          - primary:
            - [intent.md](#{intent_path}:1)
            - [#{case_workflow_overlay_path.basename}](#{case_workflow_overlay_path}:1)
          - supporting:
            - `#{intent_source}`
            - `#{canonical_source}`

          ## 8. Stop Rules

          - stop if:
            - canonical source interpretation forks
            - multiple reasonable choices change scope
            - gate closure basis is missing
            - reopen responsibility belongs to human

          ## 9. Instance Notes

          - special case caveat:
            - heuristic profile は minimal template から始める
          - dependency order:
            - `<intent gate で確定する>`
          - active feature set:
            - `<intent gate で確定する>`
        MARKDOWN
      end

      def rendered_workflow_path
        <<~MARKDOWN
          # #{slug} workflow path

          _status: bootstrap trace started_  
          _purpose: #{slug} case の workflow progression trace_

          ---

          | seq | date | actor | phase | action | status | spec_state | note |
          |-----|------|-------|-------|--------|--------|------------|------|
          | 1 | `#{today}` | `Codex` | `intent` | `bootstrap initialized` | `completed` | `intent-fixed` | canonical source と bootstrap artifact を固定 |
        MARKDOWN
      end
    end
  end
end

options = {
  force: false,
  tracks: ["Spec Track"]
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: ruby dual-reviewer-rebuild/scripts/bootstrap_reference_free_case.rb CASE_SLUG [options]"

  opts.on("--canonical-source PATH", "Canonical source path or note") do |value|
    options[:canonical_source] = value
  end

  opts.on("--intent-source PATH", "Intent source path or note") do |value|
    options[:intent_source] = value
  end

  opts.on("--tracks CSV", "Tracks to record in initial spec.json (default: Spec Track)") do |value|
    options[:tracks] = value.split(",").map(&:strip).reject(&:empty?)
  end

  opts.on("--force", "Overwrite existing bootstrap targets") do
    options[:force] = true
  end
end

parser.parse!
slug = ARGV.shift

if slug.nil? || slug.empty?
  warn parser.to_s
  exit 1
end

canonical_source = options[:canonical_source] || "<set canonical source>"
intent_source = options[:intent_source] || "<set intent source>"

DualReviewer::Scripts::ReferenceFreeCaseBootstrap.new(
  repo_root: File.expand_path("..", __dir__),
  slug: slug,
  canonical_source: canonical_source,
  intent_source: intent_source,
  tracks: options[:tracks],
  force: options[:force]
).run
