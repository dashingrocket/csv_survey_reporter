require 'csv_hasher'

require 'chartkick'

module CpNetSurveyReporter
  class Report
    include Chartkick::Helper

    def initialize(csv_file, title='Report')
      @title = title
      @timestamp = Time.now.strftime('%c')
      @results = parse_results(csv_file)
      @questions = questions

      puts @results.first
    end

    def parse_results(csv_file)
      CSVHasher.hashify(csv_file, {original_col_as_keys: true})
    end

    def questions
      {
          'Who is your current internet provider?' => :pie,
          'Overall, how satisfied are you with your current internet provider?' => :pie,
          'How interested are you in higher speed internet service?' => :pie,
          'What kind of internet household do you live in?' => :pie
      }
      # TODO Make this a yaml?
    end

    def graph(question, type)
      case type
        when :pie
          pie_chart(count_per(question))
        else
          raise "unknown type #{type}"
      end

    end

    def count_per(question)
      counts = {}
      @results.each do |result|
        value = result[question]
        counts[value] ||= 0
        counts[value] += 1
      end
      counts
    end

    def get_binding
      binding()
    end
  end
end