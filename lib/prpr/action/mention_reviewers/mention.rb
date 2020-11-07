module Prpr
  module Action
    module MentionReviewers
      class Mention < Base
        def call
          Publisher::Adapter::Base.broadcast message
        end

        private

        def message
          channel = to_dm? ? reviewer_mention_name : room
          Prpr::Publisher::Message.new(body: body, from: from, room: channel)
        end

        def pull_request
          event.pull_request
        end

        def requested_reviewer
          event.requested_reviewer
        end

        def body
          <<-END
#{reviewer_mention_name}
#{comment_body}
#{pull_request.html_url}
          END
        end

        def comment_body
          comment = env.format(:mention_reviewers_body, pull_request)
          comment.empty? ? "Please review my PR: #{pull_request.title}" : comment
        end

        def reviewer_mention_name
          members[reviewer] || reviewer
        end

        def reviewer
          "@#{requested_reviewer.login}"
        end

        def from
          event.sender
        end

        def room
          env[:mention_comment_room]
        end

        def members
          @members ||= config.read(name).lines.map { |line|
            if line =~ / \* (\S+):\s*(\S+)/
              [$1, $2]
            end
          }.to_h
        rescue
          @members ||= {}
        end

        def config
          @config ||= Config::Github.new(repository_name)
        end

        def env
          Config::Env.default
        end

        def name
          env[:mention_comment_members] || 'MEMBERS.md'
        end

        def repository_name
          env[:mention_comment_members_repository] || event.repository.full_name
        end

        def to_dm?
          env[:mention_reviewers_to_dm] == 'true'
        end
      end
    end
  end
end
