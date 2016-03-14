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
          'Who is your current internet provider?' => {type: :pie, other: 'Other - Write In:Who is your current internet provider?'},
          'Overall, how satisfied are you with your current internet provider?' => :pie,
          'How interested are you in higher speed internet service?' => :pie,
          'What kind of internet household do you live in?' => :pie,
          # TODO DOWNLOAD/UPLOAD Comparison
          # TODO Download/Upload Raw Data,
          'How much do you currently pay for internet service per month?' => :pie,
          'Do you require internet at home for your job, education, etc?' => :pie,
          'Which best describes your primary telephone service at home?' => {type: :pie, other: 'Other - Write In:Which best describes your primary telephone service at home?'},
          'What is your resident status in Crystal Park?' => :pie,

          'Name:Contact' => {type: :summary, display: 'Name'},
          'Street Address(important if you do not currently have service or are limited to satellite):Contact' => {type: :summary, display: 'Address'},
          'Email Address(if you would like to receive updates from the internet committee):Contact' => {type: :summary, display: 'Email Address'},
          'Additional Comments' => :summary
      # TODO Add raw data table, too
      }
      # TODO Make this a yaml?
    end

    def graph(question, type)
      'Something'
      if type.is_a? Hash
        other = type[:other]
        type = type[:type]
      end

      case type
        when :pie
          pie_chart(count_per(question, other), {library: {title: question, width: 600} })
        when :summary
          # Not for graphing
        else
          raise "unknown type #{type}"
      end
    end

    def summarize
      summary = '<div class="summary-section">'
      @results.each do |result|
        summary << '<div class="summary-item">'
        questions.each do |question, type|
          if type.is_a? Hash
            display = type[:display] || question
            type = type[:type]
          else
            display = question
          end
          if type == :summary
            summary << "<div class=\"summary-item-label\">#{display}</div>"
            summary << "<div class=\"summary-item-value\"'>#{result[question]}</div>"
          end
        end
        summary << '</div>'
      end
      summary << '</div>'
      summary
    end

    def count_per(question, other = nil)
      counts = {}
      @results.each do |result|

        if other && result[other] && result[other].length > 0
          response = result[other]
        else
          response = result[question]
        end
        counts[response] ||= 0
        counts[response] += 1
      end
      counts
    end

    def get_binding
      binding()
    end
  end
end