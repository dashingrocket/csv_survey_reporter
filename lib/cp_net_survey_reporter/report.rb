require 'csv_hasher'
require 'chartkick'
require 'set'

require_relative 'version'

module CSVSurveyReporter
  class Report
    include Chartkick::Helper

    def initialize(csv_file, config)
      check_config(config)

      @title = config['report_name']
      @questions = config['questions'] || {}
      @analysis = config['analysis'] || []
      @summary = config['summary'] || {}
      @timestamp = Time.now.strftime('%c')
      @results = parse_results(csv_file)

      spec_file = File.join(__dir__, '..','..','csv_survey_reporter.gemspec')
      @spec = Gem::Specification::load spec_file
    end

    def parse_results(csv_file)
      CSVHasher.hashify(csv_file, {original_col_as_keys: true})
    end

    def get_binding
      binding()
    end

    private

    def check_config(config)
      raise 'No report_name in config' unless config['report_name']
    end
   
    def chart(question, details)
      if details.is_a? Hash
        display = details['display'] || question
        type = details['type']
      else
        type = details
        display = question
      end

      chart = ''

      case type
        when 'pie'
          chart << pie_chart(count_per(question), {
              library: {
                  title: {text: display},
                  plotOptions: {
                      pie: {
                          allowPointSelect: true,
                          cursor: 'pointer',
                          dataLabels: {
                              enabled: true,
                              format: '{point.percentage:.1f}%'
                          },
                          showInLegend: true,
                      }
                  },
                  tooltip: {
                      pointFormat: '{series.name}: <b>{point.percentage:.1f}%</b>'
                  }
              }
          })

        when 'column'
          chart << column_chart(count_per(question), {library: {title: {text: display}} })
        else
          chart << "unknown chart type '#{type}'  Details: #{details}"
      end

      chart
    end

    def analyze_chart(analysis)
      type = analysis['type']
      group = analysis['group']
      result = analysis['result']
      title = analysis['title']

      group_label = analysis['group_label'] || ''
      result_label = analysis['result_label'] || ''

      case type
        when 'column'
          column_chart(group_per_result(group, result), {
              library: {
                  title: {
                      text: title
                  },
                  xAxis: {
                      title: {
                          text: group_label
                      },
                      crosshair: true
                  },
                  yAxis: {
                      title: {
                          text: result_label
                      }
                  },
                  tooltip: {
                      headerFormat: '<span style="font-size:10px">{point.key}</span><table>',
                      pointFormat: '<tr><td style="color:{series.color};padding:0">{series.name}: </td>' +
                          '<td style="padding:0"><b>{point.y}</b></td></tr>',
                      footerFormat: '</table>',
                      shared: true,
                      useHTML: true
                  }
              }
          })
        else
          "unknown type '#{type}'"
      end
    end

    def group_per_result(group_field, result_field)
      x_axis = Set.new

      data = {}

      @results.each do |result|
        x_axis << result[group_field]
        data[result[result_field]] ||= {}
        data[result[result_field]][result[group_field]] ||= 0
        data[result[result_field]][result[group_field]] += 1
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

    def summarize(result)
      out = ''
        @summary.each do |question, details|
          display = details['display'] || question
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
  end
end