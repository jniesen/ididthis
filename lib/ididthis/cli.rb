#!/usr/bin/env ruby
require "thor"
require "ididthis"

module Ididthis
  # Class providing the command line interface processing
  class CommandLine < Thor
    class_option :color,
                 :type    => :boolean,
                 :default => true,
                 :desc    => "Colorize output"

    desc "configure", "(Re)configure the client."
    long_desc <<-CONFIGURE

    `configure` will (re)create your configuration file for you.  It will
    prompt you for your iDoneThis API Token, which you can retrieve from
    https://idonethis.com/api/token/
    CONFIGURE
    def configure
      Config.configure!
      puts "Config file created at #{Config::PATH.inspect}"
    end

    desc "post [OPTIONS] DONE", "Post a new done"
    long_desc <<-POST

    `post` will post a new done or goal to iDoneThis.
    To tag the done, simply include the tags in the done using #hashtags.
    If any tag doesn"t already exist, it will be created.
    POST
    option :date,
           :aliases => "-d",
           :type    => :string,
           :banner  => "YYYY-MM-DD",
           :desc    => "The date for this done."
    option :team,
           :aliases => "-t",
           :type    => :string,
           :default => Ididthis::Config[:team],
           :banner  => "SHORT_NAME",
           :desc    => "The team to post to."
    option :goal,
           :aliases => "-g",
           :type    => :boolean,
           :desc    => "Post a goal rather than a done"
    def post(done)
      post_options = {}
      post_options[:done_date] = options[:date] if options[:date]
      post_options[:meta_data] = options[:metadata] if options[:metadata]
      c = Ididthis::API::Client.new(Ididthis::Config[:token])
      c.post_done(
        options[:goal] ? "[] #{done}" : done, options[:team],
        post_options
      )
    end

    desc "dones [OPTIONS]", "List dones"
    long_desc <<-DONES
    DONES
    option :team,
           :aliases => "-t",
           :type    => :string,
           :default => Ididthis::Config[:team],
           :banner  => "SHORT_NAME",
           :desc    => "Show only dones from TEAM"
    option :owner,
           :aliases => "-o",
           :type    => :string,
           :banner  => "USERNAME",
           :desc    => "Show only dones belonging to USERNAME"
    option :date,
           :aliases => "-d",
           :type    => :string,
           :banner  => "YYYY-MM-DD, yesterday, or today",
           :desc    => "Show only dones from DATE"
    option :after,
           :type    => :string,
           :banner  => "YYYY-MM-DD",
           :desc    => "Show only dones on or after DATE"
    option :before,
           :type    => :string,
           :banner  => "YYYY-MM-DD",
           :desc    => "Show only dones on or before DATE"
    option :tags,
           :type    => :string,
           :banner  => "TAG...",
           :desc    => "Show only dones tagged with TAGs. Comma separated list."
    option :order,
           :type    => :string,
           :banner  => "ORDER",
           :enum    => ["created", "done_date", "-created", "-done_date"],
           :desc    => "Order results by ORDER."
    option :limit,
           :aliases => "-l",
           :type    => :numeric,
           :banner  => "LIMIT",
           :desc    => "Limit the number of results returned. Maximum of 100."
    option :page,
           :aliases => "-p",
           :type    => :numeric,
           :banner  => "PAGE",
           :desc    => "Used in conjunction with --limit to get more results."
    def dones
      query_mappings = {
        date: "done_date",
        after: "done_date_after",
        before: "done_date_before",
        order: "order_by",
        limit: "page_size" }
      params = Hash[options.map { |k, v| [query_mappings[k] || k, v] }]
      c = Ididthis::API::Client.new(Ididthis::Config[:token])
      print_dones(c.dones(params))
    end

    desc "teams", "Update your team list from the server."
    def teams
    end

  private

    # TODO: Break output to separate formatter classes
    def print_dones(dones)
      dones.each do |done|
        print format_column(done[:done_date], COLORS[:yellow])
        print format_column(done[:owner], COLORS[:green], " ")
        puts format_column(highlight_tags(done[:raw_text]), "", "\t")
      end
    end

    def highlight_tags(done_text)
      options[:color] ? done_text.gsub(/(#\b[^\s]+\b)/, "\e[31m\\1\e[0m") : done_text
    end

    def format_column(text, color_code, prefix = "", suffix = "")
      column_text = "#{prefix}#{color_code if options[:color] && color_code}"
      column_text += text
      column_text += "#{COLORS[:reset] if options[:color] && color_code}#{suffix}"
    end

    COLORS = {
      reset: "\e[0m",
      red: "\e[31m",
      green: "\e[32m",
      yellow: "\e[33m"
    }
  end
end
