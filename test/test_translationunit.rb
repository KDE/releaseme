require_relative 'lib/testme'

require_relative '../lib/translationunit'

class TestTranslationUnit < Testme
  def create(type)
    l = TranslationUnit.new(type, 'amarok', '/dev/null')
    l.target = "#{@dir}/l10n"
    l
  end

  def create_trunk
    create(TranslationUnit::TRUNK)
  end

  def create_stable
    create(TranslationUnit::STABLE)
  end

  def test_0_attr
    l = create_trunk

    assert_equal("#{@dir}/l10n", l.target)
    assert_equal(TranslationUnit::TRUNK, l.type)
    assert_equal('/dev/null', l.i18n_path)
  end

  def test_0_repo_url_init_trunk
    l = create_trunk
    assert_equal(TranslationUnit::TRUNK, l.type)
    l.init_repo_url('file://a')
    assert_equal('file://a/trunk/l10n-kf5/', l.vcs.repository)
  end

  def test_0_repo_url_init_stable
    l = create_stable
    assert_equal(TranslationUnit::STABLE, l.type)
    l.init_repo_url('file://a')
    assert_equal(l.vcs.repository, 'file://a/branches/stable/l10n-kf5/')
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
