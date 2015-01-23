require_relative 'lib/testme'

require_relative '../lib/translationunit'

class TestTranslationUnit < Testme
  def create
    l = TranslationUnit.new(TranslationUnit::TRUNK, 'amarok', '/dev/null')
    l.target = "#{@dir}/l10n"
    l
  end

  def test_0_attr
    l = create

    assert_equal(l.target, "#{@dir}/l10n")
    assert_equal(l.type, TranslationUnit::TRUNK)
    assert_equal(l.i18n_path, '/dev/null')
  end

  def test_0_repo_url_init
    l = create
    assert_equal(l.type, TranslationUnit::TRUNK)
    l.init_repo_url('file://a')
    assert_equal(l.vcs.repository, 'file://a/trunk//l10n-kf5/')
    l.init_repo_url('file://a/')
    assert_equal(l.vcs.repository, 'file://a/trunk//l10n-kf5/')
  end

  def test_invalid_inits
    assert_raise do
      TranslationUnit.new(nil, 'amarok', '/dev/null')
    end
    assert_raise do
      TranslationUnit.new(TranslationUnit::TRUNK, nil, 'null')
    end
    assert_raise do
      TranslationUnit.new(TranslationUnit::TRUNK, 'amarok', nil)
    end
  end
end
