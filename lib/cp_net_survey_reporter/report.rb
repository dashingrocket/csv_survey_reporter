require 'csv_hasher'
require 'chartkick'
require 'set'

module CpNetSurveyReporter
  class Report
    include Chartkick::Helper

    def initialize(csv_file, title='Report')
      @title = title
      @timestamp = Time.now.strftime('%c')
      @results = parse_results(csv_file)
      @questions = questions
      @analysis = analysis
      @summary = summary

      require 'pp'
      pp @results.first
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

          "Download:What speed internet service do you subscribe to? If your service offers a guaranteed minimum and an 'up to' speed, put your 'up to' speed here" => {type: :column, display: 'Subscribed Download Speed'},
          "Upload:What speed internet service do you subscribe to? If your service offers a guaranteed minimum and an 'up to' speed, put your 'up to' speed here" => {type: :column, display: 'Subscribed Upload Speed'},
          "Download:What internet speed do you typically receive during the day?If you aren't sure, consider running a speedtest at http://www.speedtest.net -- you have to be at home for the numbers to be useful" => {type: :column, display: 'Daytime Download Speed'},
          "Upload:What internet speed do you typically receive during the day?If you aren't sure, consider running a speedtest at http://www.speedtest.net -- you have to be at home for the numbers to be useful" => {type: :column, display: 'Daytime Upload Speed'},
          "Download:What internet speed do you typically receive during the evening?If you aren't sure, consider running a speedtest at http://www.speedtest.net -- you have to be at home for the numbers to be useful" => {type: :column, display: 'Evening Download Speed'},
          "Upload:What internet speed do you typically receive during the evening?If you aren't sure, consider running a speedtest at http://www.speedtest.net -- you have to be at home for the numbers to be useful" => {type: :column, display: 'Evening Upload Speed'},

          # TODO DOWNLOAD/UPLOAD Comparison
          'How much do you currently pay for internet service per month?' => :pie,
          'Do you require internet at home for your job, education, etc?' => :pie,
          'Which best describes your primary telephone service at home?' => {type: :pie, other: 'Other - Write In:Which best describes your primary telephone service at home?'},
          'What is your resident status in Crystal Park?' => :pie,
      }
      # TODO Make this a yaml?

      # TODO Satisfaction per subscriber
    end

    def analysis
      [
          {
              x: 'Who is your current internet provider?',
              y: 'Overall, how satisfied are you with your current internet provider?',
              type: :column,
              title: 'Internet Company Satisfaction'
          },
      ]
    end

    def summary
      {
          'Name:Contact' => {display: 'Name'},
          'Street Address(important if you do not currently have service or are limited to satellite):Contact' => {display: 'Address'},
          'Email Address(if you would like to receive updates from the internet committee):Contact' => {display: 'Email Address'},
          'Additional Comments' => {}
      }
    end

    def chart(question, type)
      if type.is_a? Hash
        other = type[:other]
        display = type[:display] || question
        type = type[:type]
      else
        other = nil
        display = question
      end

      chart = ''

      case type
        when :pie
          chart << pie_chart(count_per(question), {
              library: {
                  title: {text: display},
                  plotOptions: {
                      pie: {
                          allowPointSelect: true,
                          cursor: 'pointer',
                          dataLabels: {
                              enabled: false
                          },
                          showInLegend: true
                      }
                  },
                  tooltip: {
                      pointFormat: '{series.name}: <b>{point.percentage:.1f}%</b>'
                  }
              }
          })

        when :column
          chart << column_chart(count_per(question), {library: {title: {text: display}} })
        when :summary
          # Not for graphing
        else
          chart << "unknown chart type #{type}"
      end

      chart << response_counts(other) if other

      chart
    end

    def analyze_chart(analysis)
      type = analysis[:type]
      x = analysis[:x]
      y = analysis[:y]
      title = analysis[:title]

      case type
        when :column
          column_chart(x_per_y(x, y), {library: {title: {text: title}}} )
        else
          "unknown type #{type}"
      end
    end

    def x_per_y(x, y)
      x_axis = Set.new

      data = {}

      @results.each do |result|
        x_axis << result[x]
        data[result[y]] ||= {}
        data[result[y]][result[x]] ||= 0
        data[result[y]][result[x]] += 1
      end

      x_axis = x_axis.to_a.sort

      array_data = []

      data.each do |x_local, y_local|
        data_local = []

        x_axis.each do |x_item|
          y_local[x_item] ||= 0
          data_local << [x_item, y_local[x_item]]
        end

        array_data << {name: x_local, data: data_local}
      end

      array_data
    end

    def response_counts(other)
      output = '<div class="response-count">'
      output << "<div class=\"response-count-title\">#{other}</div>"
      counts = count_per(other)
      counts.each do |response, count|
        next if response.empty?
        output << "<div class=\"response-count-row\">"
        output << "<div class=\"response-count-label\">#{response}</div>"
        output << "<div class=\"response-count-value\">#{count}</div>"
        output << '</div>'
      end
      output << '</div>'
    end

    def summarize(result)
      out = ''
        @summary.each do |question, details|
          display = details[:display] || question
          out << "<div class=\"summary-item-label\">#{display}</div>"
          out << "<div class=\"summary-item-value\"'>#{result[question]}</div>"
        end
      out
    end

    def count_per(question)
      counts = {}
      @results.each do |result|
        response = result[question]
        counts[response] ||= 0
        counts[response] += 1
      end
      counts.sort.to_h
    end

    def get_binding
      binding()
    end
  end
end