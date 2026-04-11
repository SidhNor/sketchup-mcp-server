# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'pathname'

# Shared helpers for version sync and RBZ packaging tasks.
module ReleaseSupport
  extend self

  ROOT = Pathname.new(File.expand_path('..', __dir__)).freeze
  VERSION_FILE = ROOT.join('VERSION').freeze
  PYPROJECT_FILE = ROOT.join('pyproject.toml').freeze
  RUBY_VERSION_FILE = ROOT.join('src/su_mcp/version.rb').freeze
  EXTENSION_METADATA_FILE = ROOT.join('src/su_mcp/extension.json').freeze
  PYTHON_VERSION_FILE = ROOT.join('python/src/sketchup_mcp_server/version.py').freeze
  DIST_DIR = ROOT.join('dist').freeze
  SRC_DIR = ROOT.join('src').freeze
  EXTENSION_LOADER = SRC_DIR.join('su_mcp.rb').freeze
  EXTENSION_SUPPORT_DIR = SRC_DIR.join('su_mcp').freeze
  PACKAGE_BASENAME = 'su_mcp'

  def current_version
    VERSION_FILE.read(encoding: 'utf-8').strip
  end

  def release_version
    value = ENV['NEW_VERSION'].to_s.strip
    return current_version if value.empty?

    value
  end

  def package_path(version = release_version)
    DIST_DIR.join("#{PACKAGE_BASENAME}-#{version}.rbz")
  end

  def sync_version!(version)
    version = normalize_version(version)
    write_text(VERSION_FILE, "#{version}\n")
    update_regex_file(PYPROJECT_FILE, /^version = ".*"$/, %(version = "#{version}"))
    update_regex_file(RUBY_VERSION_FILE, /^\s*VERSION = ['"].*['"](?:\.freeze)?$/,
                      %(  VERSION = '#{version}'))
    update_regex_file(PYTHON_VERSION_FILE, /^__version__ = ".*"$/, %(__version__ = "#{version}"))

    metadata = JSON.parse(EXTENSION_METADATA_FILE.read(encoding: 'utf-8'))
    metadata['version'] = version
    write_text(EXTENSION_METADATA_FILE, "#{JSON.pretty_generate(metadata)}\n")
  end

  def assert_version_alignment!
    expected = current_version
    mismatches = version_checks(expected).filter_map do |path, actual|
      next if actual == expected

      "#{path.relative_path_from(ROOT)} expected #{expected.inspect}, got #{actual.inspect}"
    end

    return if mismatches.empty?

    raise "Version mismatch detected:\n#{mismatches.join("\n")}"
  end

  def package_entries
    files = [EXTENSION_LOADER]
    files.concat(
      Dir.glob(File.join(EXTENSION_SUPPORT_DIR.to_s, '**', '*'), File::FNM_DOTMATCH)
         .map { |path| Pathname.new(path) }
         .select(&:file?)
    )

    files.reject { |path| ignored_package_entry?(path) }
         .sort_by { |path| path.relative_path_from(SRC_DIR).to_s }
  end

  def ignored_package_entry?(path)
    relative = path.relative_path_from(SRC_DIR).to_s
    return true if relative.include?('/.') || relative.start_with?('.')

    ['.DS_Store', '.keep'].include?(path.basename.to_s)
  end

  def package_relative_path(path)
    path.relative_path_from(SRC_DIR).to_s
  end

  def clean_dist!
    FileUtils.mkdir_p(DIST_DIR)
    Dir.glob(DIST_DIR.join('*.rbz').to_s).each { |path| FileUtils.rm_f(path) }
  end

  private

  def version_checks(expected)
    {
      VERSION_FILE => expected,
      PYPROJECT_FILE => extract_match(
        PYPROJECT_FILE,
        /^version = "([^"]+)"$/,
        'pyproject version'
      ),
      RUBY_VERSION_FILE => extract_match(
        RUBY_VERSION_FILE,
        /^\s*VERSION = ['"]([^'"]+)['"]/,
        'Ruby version'
      ),
      PYTHON_VERSION_FILE => extract_match(
        PYTHON_VERSION_FILE,
        /^__version__ = "([^"]+)"/,
        'Python version'
      ),
      EXTENSION_METADATA_FILE => extension_metadata_version
    }
  end

  def extension_metadata_version
    JSON.parse(
      EXTENSION_METADATA_FILE.read(encoding: 'utf-8')
    ).fetch('version')
  end

  def normalize_version(version)
    value = version.to_s.strip
    raise 'Version cannot be empty' if value.empty?

    value
  end

  def extract_match(path, pattern, label)
    match = path.read(encoding: 'utf-8').match(pattern)
    raise "Could not find #{label} in #{path.relative_path_from(ROOT)}" unless match

    match[1]
  end

  def update_regex_file(path, pattern, replacement)
    content = path.read(encoding: 'utf-8')
    updated = content.sub(pattern, replacement)
    raise "Could not update #{path.relative_path_from(ROOT)}" if updated == content

    write_text(path, updated)
  end

  def write_text(path, content)
    path.dirname.mkpath
    path.write(content, mode: 'w', encoding: 'utf-8')
  end
end
