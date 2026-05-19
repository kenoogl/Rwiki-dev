# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"
require "fileutils"
require "pathname"
require "json"

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

# Task 3: claim mapping model（論文インターフェース所有・スクラッチ）。
# 根拠: tasks.md Task 3、Requirement 1（受入 1〜6）、Requirement 4 受入 1、
#       design「Claim Mapping Model §1〜§2」。
#       適合レビュー 2026-05-19 Finding 1/2/8（evaluation 新実体スキーマ
#       不一致）・Finding 10（claim taxonomy ハードコード）解消。
#
# 決定的固定入力＝波0版固定 評価実出力 fixture。手で値を作らない。
class TestClaimMap < Minitest::Test
  ROOT = Pathname(__dir__).join("..", "..").expand_path
  ANALYSIS = ROOT + "tests/fixtures/paper_interface/analysis"

  def setup
    require_relative "../../scripts/paper_interface/v2/claim_map_builder"
    require_relative "../../scripts/paper_interface/v2/reference"
    @ref = DualReviewer::PaperInterfaceV2::Reference
    @builder = DualReviewer::PaperInterfaceV2::ClaimMapBuilder.new(
      analysis_root: ANALYSIS.to_s
    )
  end

  def build
    @builder.build
  end

  # design §1: claim entry は claim_id / claim_text /
  # supporting_artifact_refs / maturity_label / caveat_refs /
  # provenance_refs を持つ。
  def test_claim_entry_shape
    cm = build
    assert cm["claims"].size.positive?
    cm["claims"].each do |c|
      %w[claim_id claim_text supporting_artifact_refs maturity_label
         caveat_refs provenance_refs].each do |k|
        assert c.key?(k), "claim entry must have #{k}"
      end
    end
  end

  # Requirement 1 受入 6 / design §1: claim_id は安定識別子。
  # 全 claim が一意な claim_id を持つ。
  def test_claim_ids_unique_and_stable
    ids = build["claims"].map { |c| c["claim_id"] }
    assert_equal ids.size, ids.uniq.size
    ids.each { |i| assert i.is_a?(String) && !i.empty? }
  end

  # Requirement 1 受入 5 / design §3: supporting_artifact_refs と
  # provenance_refs は構造化参照（裸パス・"path#code" 文字列不可）。
  def test_refs_are_structured_not_bare_strings
    build["claims"].each do |c|
      assert @ref.all_valid?(c["supporting_artifact_refs"]),
             "supporting_artifact_refs must be structured refs"
      assert @ref.all_valid?(c["provenance_refs"]),
             "provenance_refs must be structured refs"
      assert @ref.all_valid?(c["caveat_refs"])
      c["supporting_artifact_refs"].each do |r|
        refute r["target_path"].include?("#"),
               "no basename/identifier string concatenation"
      end
    end
  end

  # Requirement 1 受入 4 / design §2: supporting source は
  # experiments/analysis/ 相対の標準 source に限定。runtime raw を
  # 一次入力にしない。
  def test_supporting_sources_limited_to_analysis_relative
    allowed = %w[
      comparisons/treatment_comparisons.json
      comparisons/phase_comparisons.json
      classifications/exclusion_report.json
      caveats/caveat_register.json
    ]
    build["claims"].each do |c|
      c["supporting_artifact_refs"].each do |r|
        rel = r["target_path"].sub(%r{\Aexperiments/analysis/}, "")
        ok = allowed.include?(rel) || rel.start_with?("metrics/")
        assert ok, "non-standard supporting source: #{r['target_path']}"
        refute r["target_path"].include?("experiments/runs/"),
               "runtime raw must not be primary input"
      end
    end
  end

  # Requirement 1 受入 4 / design Design Drivers: evaluation output が
  # 存在しない場合は生ログにフォールバックせず評価プロセス実行を要求。
  def test_missing_evaluation_output_requires_evaluation_run
    b = DualReviewer::PaperInterfaceV2::ClaimMapBuilder.new(
      analysis_root: (ROOT + "tests/fixtures/_does_not_exist").to_s
    )
    err = assert_raises(RuntimeError) { b.build }
    assert_match(/evaluation process must be run/i, err.message)
    refute_match(/raw log|experiments\/runs/i, err.message)
  end

  # Requirement 1 受入 3: direct evidence と caveated/preliminary
  # evidence を区別する（maturity_label と caveat_refs で表現）。
  def test_direct_vs_caveated_distinction
    build["claims"].each do |c|
      assert_includes %w[mature preliminary exploratory],
                       c["maturity_label"]
    end
  end

  # 証拠追跡性の機械検証（Task 9 検証対象1）: claim の
  # supporting_artifact_refs / provenance_refs が Reference Format に従い
  # 参照先 artifact まで machine 解決できる（design §3「基準ディレクトリ
  # 起点」＝experiments/analysis/ を fixture root に束ねた base で解決。
  # repo 全体でなく基準ディレクトリ起点なのが spec の機械検証契約）。
  def test_evidence_traceability_machine_resolvable
    # fixture analysis root を experiments/analysis/ の基準ディレクトリと
    # して臨時 repo-like tree を構成し target_path 完全一致で解決する。
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "experiments"))
      FileUtils.cp_r(ANALYSIS.to_s, File.join(dir, "experiments", "analysis"))
      build["claims"].each do |c|
        (c["supporting_artifact_refs"] + c["provenance_refs"]).each do |r|
          res = @ref.resolve(r, repo_root: dir)
          assert res[:resolved],
                 "ref must be machine-resolvable: #{r['target_path']}"
          refute r["target_path"].include?("#"),
                 "no basename/identifier string concatenation in ref"
        end
      end
    end
  end

  # Requirement 1 受入 5: versioned evidence に辿れない
  # claim-supporting artifact を許さない（provenance_refs が manifest を
  # 指し analysis_logic_version へ辿れる）。
  def test_all_claims_trace_to_versioned_evidence
    build["claims"].each do |c|
      manifest_ref = c["provenance_refs"].find do |r|
        r["ref_type"] == "analysis_run_manifest"
      end
      refute_nil manifest_ref,
                 "claim must carry analysis_run_manifest provenance"
    end
  end
end
