module SpreeProductImport
  VERSION = '0.0.38'.freeze

  module_function

  # Returns the version of the currently loaded SpreeProductImport as a
  # <tt>Gem::Version</tt>.
  def version
    Gem::Version.new VERSION
  end
end
