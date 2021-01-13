# frozen_string_literal=true

require 'octokit'
require 'optparse'

stack = Faraday::RackBuilder.new do |builder|
  builder.use Faraday::Request::Retry, exceptions: [Octokit::ServerError]
  builder.use Octokit::Middleware::FollowRedirects
  builder.use Octokit::Response::RaiseError
  builder.use Octokit::Response::FeedParser
  builder.response :logger
  builder.adapter Faraday.default_adapter
end
Octokit.middleware = stack

module Github
  module Deployment
    module Status
      class CLI
        def initialize(argv = ARGV)
          @argv = argv
        end

        def perform
          parse_options @argv
          deployment = octokit.create_deployment(@repo, @ref,
                                                 environment: @environment,
                                                 auto_merge: false,
                                                 required_contexts: [])
          p deployment.inspect
          octokit.create_deployment_status(deployment[:url],
                                           'success',
                                           target_url: @target_url,
                                           description: @description)
        end

        def octokit
          @octokit ||= Octokit::Client.new access_token: @access_token
        end

        def parse_options(argv)
          OptionParser.new do |opt|
            opt.on('-a', '--access-token V', String) do |v|
              @access_token = v
            end
            opt.on('-r', '--repo V', String) do |v|
              @repo = v
            end
            opt.on('--ref V', String) do |v|
              @ref = v
            end
            opt.on('--environment V', String) do |v|
              @environment = v
            end
            opt.on('--description V', String) do |v|
              @description = v
            end
            opt.on('--target-url V', String) do |v|
              @target_url = v
            end

            opt.parse argv
          end
        end
      end
    end
  end
end
