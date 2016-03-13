require 'erb'

module CpNetSurveyReporter
  class ReportGenerator
    def initialize (input_file, output_dir)
      @input_file = input_file
      @output_dir = output_dir
    end

    def generate(template_file)
      erb = ERB.new(File.read(template_file))
      puts erb.result
    end
  end
end