require "codeclimate-test-reporter"

SimpleCov.formatters  = [SimpleCov::Formatter::HTMLFormatter,CodeClimate::TestReporter::Formatter]

SimpleCov.start do
  add_filter '/spec/'
end