require 'erb'

module CpNetSurveyReporter
  class ReportGenerator
    def initialize (output_dir)
      FileUtils.rm_rf output_dir if File.exists? output_dir
      FileUtils.mkdir_p output_dir
      @output_dir = output_dir
    end

    def generate(report, template_file)
      copy_assets
      generate_file(report, template_file)
    end

    private
    def copy_assets
      FileUtils.cp_r File.join(__dir__, '..', '..','app','assets','.'), @output_dir
    end

    def generate_file(report, template_file)
      file = File.join(@output_dir, 'index.html')
      erb = ERB.new(File.read(template_file))
      result = erb.result(report.get_binding)
      File.write(file, result)
      puts "Result written to #{file}"
    end
  end
end