require 'spec_helper'
require 'api_helper'

describe "/user-feedback" do

  fixtures :users, :seats

  before(:all) do
    @CREATE_TOKENS=true
  end

  shared_examples_for "user_feedback" do
      it "should return id" do
          @feedback_results.each_with_index do |feedback_result, i|
              expect(@feedback[i]["id"]).to eq(feedback_result["id"])
          end
      end
      it "should return sprint_id" do
          @feedback_results.each_with_index do |feedback_result, i|
              expect(@feedback[i]["sprint_id"]).to eq(feedback_result["sprint_id"])
          end
      end
      it "should return state" do
          @feedback_results.each_with_index do |feedback_result, i|
              expect(@feedback[i]["state_id"]).to eq(feedback_result["state_id"])
          end
      end
      it "should return project" do
          @feedback_results.each_with_index do |feedback_result, i|
              expect(@feedback[i]["project_id"]).to eq(feedback_result["project_id"])
          end
      end
  end

  shared_examples_for "user_feedback_comment" do
      it_behaves_like "user_feedback"
      it "should return comment" do
          @feedback_results.each_with_index do |feedback_result, i|
              expect(@feedback[i]["comment_id"]).to eq(feedback_result["comment_id"])
          end
      end
  end

  shared_examples_for "user_feedback_vote" do
      it_behaves_like "user_feedback"
      it "should return vote" do
          @feedback_results.each_with_index do |feedback_result, i|
              expect(@feedback[i]["vote_id"]).to eq(feedback_result["vote_id"])
          end
      end
  end

  shared_examples_for "user_feedback_contributor" do
      it "should return contributor" do
          @feedback_results.each_with_index do |feedback_result, i|
              expect(@feedback[i]["contributor_id"]).to eq(feedback_result["contributor_id"])
          end
      end
  end

  describe "GET /aggregate-comments" do
      fixtures :users, :comments, :sprint_timelines, :sprint_skillsets, :user_skillsets, :skillsets, :roles, :user_roles, :sprint_states, :role_states, :projects, :sprints
      context "user_id" do
          before(:each) do
              @user_id = users(:adam_admin).id
              @skillset_id = skillsets(:skillset_1).id
              @role_id = roles(:product).id
          end
          context "filter by" do
              context "skillset_id" do
                  before(:each) do
                      get "/users/#{@user_id}/aggregate-comments", {:skillset_id => @skillset_id}.to_json
                      @feedback = JSON.parse(last_response.body)
                      @feedback_results = @mysql_client.query("SELECT sprint_timelines.* FROM sprint_timelines INNER JOIN comments ON (sprint_timelines.comment_id = comments.id and sprint_timelines.comment_id IS NOT NULL) INNER JOIN sprint_states ON sprint_states.id = comments.sprint_state_id INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id = sprint_states.sprint_id LEFT JOIN user_skillsets ON (user_skillsets.skillset_id = sprint_skillsets.skillset_id AND user_skillsets.active = 1) WHERE sprint_timelines.user_id = #{@user_id} AND user_skillsets.skillset_id = #{@skillset_id} GROUP BY sprint_timelines.id")
                  end
                  it_behaves_like "ok"
                  it_behaves_like "user_feedback_comment"
              end
              context "role_id" do
                  before(:each) do
                      get "/users/#{@user_id}/aggregate-comments", {:role_id => @role_id}.to_json
                      @feedback = JSON.parse(last_response.body)
                      @feedback_results = @mysql_client.query("SELECT sprint_timelines.* FROM sprint_timelines INNER JOIN comments ON (sprint_timelines.comment_id = comments.id and sprint_timelines.comment_id IS NOT NULL) INNER JOIN sprint_states ON sprint_states.id = comments.sprint_state_id INNER JOIN role_states ON sprint_states.state_id = role_states.state_id LEFT JOIN user_roles ON (user_roles.role_id = role_states.role_id AND user_roles.active = 1) WHERE sprint_timelines.user_id = #{@user_id} AND user_roles.role_id = #{@role_id} GROUP BY sprint_timelines.id")
                  end
                  it_behaves_like "ok"
                  it_behaves_like "user_feedback_comment"
              end
              context "skillset_id&role_id" do
                  before(:each) do
                      get "/users/#{@user_id}/aggregate-comments", {:skillset_id => @skillset_id, :role_id => @role_id}.to_json
                      @feedback = JSON.parse(last_response.body)
                      @feedback_results = @mysql_client.query("SELECT sprint_timelines.* FROM sprint_timelines INNER JOIN comments ON (sprint_timelines.comment_id = comments.id and sprint_timelines.comment_id IS NOT NULL) INNER JOIN sprint_states ON sprint_states.id = comments.sprint_state_id INNER JOIN role_states ON sprint_states.state_id = role_states.state_id INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id = sprint_states.sprint_id LEFT JOIN user_skillsets ON (user_skillsets.skillset_id = sprint_skillsets.skillset_id AND user_skillsets.active = 1) LEFT JOIN user_roles ON (user_roles.role_id = role_states.role_id AND user_roles.active = 1) WHERE sprint_timelines.user_id = #{@user_id} AND user_skillsets.skillset_id = #{@skillset_id} AND user_roles.role_id = #{@role_id} GROUP BY sprint_timelines.id")
                  end
                  it_behaves_like "ok"
                  it_behaves_like "user_feedback_comment"
              end
          end
      end
      context "me" do
          context "unauthorized" do
              context "skillset_id" do
                  before(:each) do
                      get "/users/me/aggregate-comments", {:skillset_id => @skillset_id}.to_json
                  end
                  it_behaves_like "unauthorized"
              end
              context "role_id" do
                  before(:each) do
                      get "/users/me/aggregate-comments", {:role_id => @role_id}.to_json
                  end
                  it_behaves_like "unauthorized"
              end
              context "skillset_id&role_id" do
                  before(:each) do
                      get "/users/me/aggregate-comments", {:skillset_id => @skillset_id, :role_id => @role_id}.to_json
                  end
                  it_behaves_like "unauthorized"
              end
          end
      end
  end

  describe "GET /aggregate-votes" do
      fixtures :users, :votes, :sprint_timelines, :sprint_skillsets, :user_skillsets, :skillsets, :roles, :user_roles, :sprint_states, :role_states, :projects, :sprints
      context "user_id" do
          before(:each) do
              @user_id = users(:adam_admin).id
              @skillset_id = skillsets(:skillset_1).id
              @role_id = roles(:product).id
          end
          context "filter by" do
              context "skillset_id" do
                  before(:each) do
                      get "/users/#{@user_id}/aggregate-votes?", {:skillset_id => @skillset_id}.to_json
                      @feedback = JSON.parse(last_response.body)
                      @feedback_results = @mysql_client.query("SELECT sprint_timelines.* FROM sprint_timelines INNER JOIN votes ON (sprint_timelines.vote_id = votes.id and sprint_timelines.vote_id IS NOT NULL) INNER JOIN sprint_states ON sprint_states.id = votes.sprint_state_id INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id = sprint_states.sprint_id LEFT JOIN user_skillsets ON (user_skillsets.skillset_id = sprint_skillsets.skillset_id AND user_skillsets.active = 1) WHERE sprint_timelines.user_id = #{@user_id} AND user_skillsets.skillset_id = #{@skillset_id} GROUP BY sprint_timelines.id")
                  end
                  it_behaves_like "ok"
                  it_behaves_like "user_feedback_vote"
              end
              context "role_id" do
                  before(:each) do
                      get "/users/#{@user_id}/aggregate-votes", {:role_id => @role_id}.to_json
                      @feedback = JSON.parse(last_response.body)
                      @feedback_results = @mysql_client.query("SELECT sprint_timelines.* FROM sprint_timelines INNER JOIN votes ON (sprint_timelines.vote_id = votes.id and sprint_timelines.vote_id IS NOT NULL) INNER JOIN sprint_states ON sprint_states.id = votes.sprint_state_id INNER JOIN role_states ON sprint_states.state_id = role_states.state_id LEFT JOIN user_roles ON (user_roles.role_id = role_states.role_id AND user_roles.active = 1) WHERE sprint_timelines.user_id = #{@user_id} AND user_roles.role_id = #{@role_id} GROUP BY sprint_timelines.id")
                  end
                  it_behaves_like "ok"
                  it_behaves_like "user_feedback_vote"
              end
              context "skillset_id&role_id" do
                  before(:each) do
                      get "/users/#{@user_id}/aggregate-votes", {:skillset_id => @skillset_id, :role_id => @role_id}.to_json
                      @feedback = JSON.parse(last_response.body)
                      @feedback_results = @mysql_client.query("SELECT sprint_timelines.* FROM sprint_timelines INNER JOIN votes ON (sprint_timelines.vote_id = votes.id and sprint_timelines.vote_id IS NOT NULL) INNER JOIN sprint_states ON sprint_states.id = votes.sprint_state_id INNER JOIN role_states ON sprint_states.state_id = role_states.state_id INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id = sprint_states.sprint_id LEFT JOIN user_skillsets ON (user_skillsets.skillset_id = sprint_skillsets.skillset_id AND user_skillsets.active = 1) LEFT JOIN user_roles ON (user_roles.role_id = role_states.role_id AND user_roles.active = 1) WHERE sprint_timelines.user_id = #{@user_id} AND user_skillsets.skillset_id = #{@skillset_id} AND user_roles.role_id = #{@role_id} GROUP BY sprint_timelines.id")
                  end
                  it_behaves_like "ok"
                  it_behaves_like "user_feedback_vote"
              end
          end
      end
      context "me" do
          context "unauthorized" do
              context "skillset" do
                  before(:each) do
                      get "/users/me/aggregate-votes", {:skillset_id => @skillset_id}.to_json
                  end
                  it_behaves_like "unauthorized"
              end
              context "role" do
                  before(:each) do
                      get "/users/me/aggregate-votes", {:role_id => @role_id}.to_json
                  end
                  it_behaves_like "unauthorized"
              end
              context "skillset&role" do
                  before(:each) do
                      get "/users/me/aggregate-votes", {:skillset_id => @skillset_id, :role_id => @role_id}.to_json
                  end
                  it_behaves_like "unauthorized"
              end
          end
      end
  end

  describe "GET /aggregate-contributors" do
      fixtures :users, :contributors, :sprint_timelines, :sprint_skillsets, :user_skillsets, :skillsets, :roles, :user_roles, :sprint_states, :role_states, :projects, :sprints
      context "user_id" do
          before(:each) do
              @user_id = users(:adam_admin).id
              @skillset_id = skillsets(:skillset_1).id
              @role_id = roles(:product).id
          end
          context "filter by" do
              context "skillset_id" do
                  before(:each) do
                      get "/users/#{@user_id}/aggregate-contributors", {:skillset_id => @skillset_id}.to_json
                      @feedback = JSON.parse(last_response.body)
                      @feedback_results = @mysql_client.query("SELECT contributors.* FROM contributors INNER JOIN sprint_states ON contributors.sprint_state_id = sprint_states.id INNER JOIN sprints ON sprint_states.sprint_id = sprints.id INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id = sprint_states.sprint_id LEFT JOIN user_skillsets ON (user_skillsets.skillset_id = sprint_skillsets.skillset_id AND user_skillsets.active = 1) WHERE user_skillsets.skillset_id = #{@skillset_id} AND contributors.user_id = #{@user_id} GROUP BY contributors.id")
                  end
                  it_behaves_like "ok"
                  it_behaves_like "user_feedback_contributor"
              end
              context "role_id" do
                  before(:each) do
                      get "/users/#{@user_id}/aggregate-contributors", {:role_id => @role_id}.to_json
                      @feedback = JSON.parse(last_response.body)
                      @feedback_results = @mysql_client.query("SELECT contributors.* FROM contributors INNER JOIN sprint_states ON contributors.sprint_state_id = sprint_states.id INNER JOIN sprints ON sprint_states.sprint_id = sprints.id INNER JOIN role_states ON sprint_states.state_id = role_states.state_id LEFT JOIN user_roles ON (user_roles.role_id = role_states.role_id AND user_roles.active = 1) WHERE user_roles.role_id = #{@role_id} AND contributors.user_id = #{@user_id} GROUP BY contributors.id")
                  end
                  it_behaves_like "ok"
                  it_behaves_like "user_feedback_contributor"
              end
              context "skillset_id&role_id" do
                  before(:each) do
                      get "/users/#{@user_id}/aggregate-contributors", {:skillset_id => @skillset_id, :role_id => @role_id}.to_json
                      @feedback = JSON.parse(last_response.body)
                      @feedback_results = @mysql_client.query("SELECT contributors.* FROM contributors INNER JOIN sprint_states ON contributors.sprint_state_id = sprint_states.id INNER JOIN sprints ON sprint_states.sprint_id = sprints.id INNER JOIN role_states ON sprint_states.state_id = role_states.state_id INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id = sprint_states.sprint_id LEFT JOIN user_skillsets ON (user_skillsets.skillset_id = sprint_skillsets.skillset_id AND user_skillsets.active = 1) LEFT JOIN user_roles ON (user_roles.role_id = role_states.role_id AND user_roles.active = 1) WHERE user_skillsets.skillset_id = #{@skillset_id} AND user_roles.role_id = #{@role_id} AND contributors.user_id = #{@user_id} GROUP BY contributors.id")
                  end
                  it_behaves_like "ok"
                  it_behaves_like "user_feedback_contributor"
              end
          end
      end
      context "me" do
          context "unauthorized" do
              context "skillset" do
                  before(:each) do
                      get "/users/me/aggregate-contributors", {:skillset_id => @skillset_id}.to_json
                  end
                  it_behaves_like "unauthorized"
              end
              context "role" do
                  before(:each) do
                      get "/users/me/aggregate-contributors", {:role_id => @role_id}.to_json
                  end
                  it_behaves_like "unauthorized"
              end
              context "skillset&role" do
                  before(:each) do
                      get "/users/me/aggregate-contributors", {:skillset_id => @skillset_id, :role_id => @role_id}.to_json
                  end
                  it_behaves_like "unauthorized"
              end
          end
      end
  end

  describe "GET /aggregate-comments-received" do
      fixtures :users, :contributors, :comments, :sprint_timelines, :sprint_skillsets, :user_skillsets, :skillsets, :roles, :user_roles, :sprint_states, :role_states, :projects, :sprints
      context "user_id" do
          before(:each) do
              @user_id = users(:adam_confirmed).id
              @skillset_id = skillsets(:skillset_1).id
              @role_id = roles(:product).id
          end
          context "filter by" do
              context "skillset_id" do
                  before(:each) do
                      get "/users/#{@user_id}/aggregate-comments-received", {:skillset_id => @skillset_id}.to_json
                      @feedback = JSON.parse(last_response.body)
                      @feedback_results = @mysql_client.query("SELECT sprint_timelines.* FROM sprint_timelines INNER JOIN contributors ON (sprint_timelines.contributor_id = contributors.id AND contributors.user_id != sprint_timelines.user_id) INNER JOIN comments ON (sprint_timelines.comment_id = comments.id and sprint_timelines.comment_id IS NOT NULL) INNER JOIN sprint_states ON sprint_states.id = comments.sprint_state_id INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id = sprint_states.sprint_id LEFT JOIN user_skillsets ON (user_skillsets.skillset_id = sprint_skillsets.skillset_id AND user_skillsets.active = 1) WHERE user_skillsets.skillset_id = #{@skillset_id} AND contributors.user_id = #{@user_id} GROUP BY sprint_timelines.id")
                  end
                  it_behaves_like "ok"
                  it_behaves_like "user_feedback_comment"
              end
              context "role_id" do
                  before(:each) do
                      get "/users/#{@user_id}/aggregate-comments-received", {:role_id => @role_id}.to_json
                      @feedback = JSON.parse(last_response.body)
                      @feedback_results = @mysql_client.query("SELECT sprint_timelines.* FROM sprint_timelines INNER JOIN contributors ON (sprint_timelines.contributor_id = contributors.id AND contributors.user_id != sprint_timelines.user_id) INNER JOIN comments ON (sprint_timelines.comment_id = comments.id and sprint_timelines.comment_id IS NOT NULL) INNER JOIN sprint_states ON sprint_states.id = comments.sprint_state_id INNER JOIN role_states ON sprint_states.state_id = role_states.state_id LEFT JOIN user_roles ON (user_roles.role_id = role_states.role_id AND user_roles.active = 1) WHERE user_roles.role_id = #{@role_id} AND contributors.user_id = #{@user_id} GROUP BY sprint_timelines.id")
                  end
                  it_behaves_like "ok"
                  it_behaves_like "user_feedback_comment"
              end
              context "skillset_id&role_id" do
                  before(:each) do
                      get "/users/#{@user_id}/aggregate-comments-received", {:skillset_id => @skillset_id, :role_id => @role_id}.to_json
                      @feedback = JSON.parse(last_response.body)
                      @feedback_results = @mysql_client.query("SELECT sprint_timelines.* FROM sprint_timelines INNER JOIN contributors ON (sprint_timelines.contributor_id = contributors.id AND contributors.user_id != sprint_timelines.user_id) INNER JOIN comments ON (sprint_timelines.comment_id = comments.id and sprint_timelines.comment_id IS NOT NULL) INNER JOIN sprint_states ON sprint_states.id = comments.sprint_state_id INNER JOIN role_states ON sprint_states.state_id = role_states.state_id INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id = sprint_states.sprint_id LEFT JOIN user_skillsets ON (user_skillsets.skillset_id = sprint_skillsets.skillset_id AND user_skillsets.active = 1) LEFT JOIN user_roles ON (user_roles.role_id = role_states.role_id AND user_roles.active = 1) WHERE user_skillsets.skillset_id = #{@skillset_id} AND user_roles.role_id = #{@role_id} AND contributors.user_id = #{@user_id} GROUP BY sprint_timelines.id")
                  end
                  it_behaves_like "ok"
                  it_behaves_like "user_feedback_comment"
              end
          end
      end
      context "me" do
          context "unauthorized" do
              context "skillset" do
                  before(:each) do
                      get "/users/me/aggregate-comments-received", {:skillset_id => @skillset_id}.to_json
                  end
                  it_behaves_like "unauthorized"
              end
              context "role" do
                  before(:each) do
                      get "/users/me/aggregate-comments-received", {:role_id => @role_id}.to_json
                  end
                  it_behaves_like "unauthorized"
              end
              context "skillset&role" do
                  before(:each) do
                      get "/users/me/aggregate-comments-received", {:skillset_id => @skillset_id, :role_id => @role_id}.to_json
                  end
                  it_behaves_like "unauthorized"
              end
          end
      end
  end

  describe "GET /aggregate-votes-received" do
      fixtures :users, :contributors, :votes, :sprint_timelines, :sprint_skillsets, :user_skillsets, :skillsets, :roles, :user_roles, :sprint_states, :role_states, :projects, :sprints
      context "user_id" do
          before(:each) do
              @user_id = users(:adam_confirmed).id
              @skillset_id = skillsets(:skillset_1).id
              @role_id = roles(:product).id
          end
          context "filter by" do
              context "skillset_id" do
                  before(:each) do
                      get "/users/#{@user_id}/aggregate-votes-received", {:skillset_id => @skillset_id}.to_json
                      @feedback = JSON.parse(last_response.body)
                      @feedback_results = @mysql_client.query("SELECT sprint_timelines.* FROM sprint_timelines INNER JOIN contributors ON (sprint_timelines.contributor_id = contributors.id AND contributors.user_id != sprint_timelines.user_id) INNER JOIN votes ON (sprint_timelines.vote_id = votes.id and sprint_timelines.vote_id IS NOT NULL) INNER JOIN sprint_states ON sprint_states.id = votes.sprint_state_id INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id = sprint_states.sprint_id LEFT JOIN user_skillsets ON (user_skillsets.skillset_id = sprint_skillsets.skillset_id AND user_skillsets.active = 1) WHERE user_skillsets.skillset_id = #{@skillset_id} AND contributors.user_id = #{@user_id} GROUP BY sprint_timelines.id")
                  end
                  it_behaves_like "ok"
                  it_behaves_like "user_feedback_vote"
              end
              context "role_id" do
                  before(:each) do
                      get "/users/#{@user_id}/aggregate-votes-received", {:role_id => @role_id}.to_json
                      @feedback = JSON.parse(last_response.body)
                      @feedback_results = @mysql_client.query("SELECT sprint_timelines.* FROM sprint_timelines INNER JOIN contributors ON (sprint_timelines.contributor_id = contributors.id AND contributors.user_id != sprint_timelines.user_id) INNER JOIN votes ON (sprint_timelines.vote_id = votes.id and sprint_timelines.vote_id IS NOT NULL) INNER JOIN sprint_states ON sprint_states.id = votes.sprint_state_id INNER JOIN role_states ON sprint_states.state_id = role_states.state_id LEFT JOIN user_roles ON (user_roles.role_id = role_states.role_id AND user_roles.active = 1) WHERE user_roles.role_id = #{@role_id} AND contributors.user_id = #{@user_id} GROUP BY sprint_timelines.id")
                  end
                  it_behaves_like "ok"
                  it_behaves_like "user_feedback_vote"
              end
              context "skillset_id&role_id" do
                  before(:each) do
                      get "/users/#{@user_id}/aggregate-votes-received", {:skillset_id => @skillset_id, :role_id => @role_id}.to_json
                      @feedback = JSON.parse(last_response.body)
                      @feedback_results = @mysql_client.query("SELECT sprint_timelines.* FROM sprint_timelines INNER JOIN contributors ON (sprint_timelines.contributor_id = contributors.id AND contributors.user_id != sprint_timelines.user_id) INNER JOIN votes ON (sprint_timelines.vote_id = votes.id and sprint_timelines.vote_id IS NOT NULL) INNER JOIN sprint_states ON sprint_states.id = votes.sprint_state_id INNER JOIN role_states ON sprint_states.state_id = role_states.state_id INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id = sprint_states.sprint_id LEFT JOIN user_skillsets ON (user_skillsets.skillset_id = sprint_skillsets.skillset_id AND user_skillsets.active = 1) LEFT JOIN user_roles ON (user_roles.role_id = role_states.role_id AND user_roles.active = 1) WHERE user_skillsets.skillset_id = #{@skillset_id} AND user_roles.role_id = #{@role_id} AND contributors.user_id = #{@user_id} GROUP BY sprint_timelines.id")
                  end
                  it_behaves_like "ok"
                  it_behaves_like "user_feedback_vote"
              end
          end
      end
      context "me" do
          context "unauthorized" do
              context "skillset" do
                  before(:each) do
                      get "/users/me/aggregate-votes-received", {:skillset_id => @skillset_id}.to_json
                  end
                  it_behaves_like "unauthorized"
              end
              context "role" do
                  before(:each) do
                      get "/users/me/aggregate-votes-received", {:role_id => @role_id}.to_json
                  end
                  it_behaves_like "unauthorized"
              end
              context "skillset&role" do
                  before(:each) do
                      get "/users/me/aggregate-votes-received", {:skillset_id => @skillset_id, :role_id => @role_id}.to_json
                  end
                  it_behaves_like "unauthorized"
              end
          end
      end
  end

  describe "GET /aggregate-contributors-winner-set" do
      fixtures :users, :contributors, :sprint_timelines, :sprint_skillsets, :user_skillsets, :skillsets, :roles, :user_roles, :sprint_states, :role_states, :projects, :sprints
      context "user_id" do
          before(:each) do
              @user_id = users(:adam_confirmed).id
              @skillset_id = skillsets(:skillset_1).id
              @role_id = roles(:product).id
          end
          context "filter by" do
              context "skillset_id" do
                  before(:each) do
                      get "/users/#{@user_id}/aggregate-contributors-received", {:skillset_id => @skillset_id}.to_json
                      @feedback = JSON.parse(last_response.body)
                      @feedback_results = @mysql_client.query("SELECT sprint_timelines.* FROM sprint_timelines INNER JOIN contributors ON (sprint_timelines.contributor_id = contributors.id and sprint_timelines.diff='winner') INNER JOIN sprint_states ON sprint_states.id = contributors.sprint_state_id INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id = sprint_states.sprint_id LEFT JOIN user_skillsets ON (user_skillsets.skillset_id = sprint_skillsets.skillset_id AND user_skillsets.active = 1) WHERE user_skillsets.skillset_id = #{@skillset_id} AND contributors.user_id = #{@user_id} GROUP BY sprint_timelines.id")
                  end
                  it_behaves_like "ok"
                  it_behaves_like "user_feedback_contributor"
              end
              context "role_id" do
                  before(:each) do
                      get "/users/#{@user_id}/aggregate-contributors-received", {:role_id => @role_id}.to_json
                      @feedback = JSON.parse(last_response.body)
                      @feedback_results = @mysql_client.query("SELECT sprint_timelines.* FROM sprint_timelines INNER JOIN contributors ON (sprint_timelines.contributor_id = contributors.id and sprint_timelines.diff='winner') INNER JOIN sprint_states ON sprint_states.id = contributors.sprint_state_id INNER JOIN role_states ON sprint_states.state_id = role_states.state_id LEFT JOIN user_roles ON (user_roles.role_id = role_states.role_id AND user_roles.active = 1) WHERE user_roles.role_id = #{@role_id} AND contributors.user_id = #{@user_id} GROUP BY sprint_timelines.id")
                  end
                  it_behaves_like "ok"
                  it_behaves_like "user_feedback_contributor"
              end
              context "skillset_id&role_id" do
                  before(:each) do
                      get "/users/#{@user_id}/aggregate-contributors-received", {:skillset_id => @skillset_id, :role_id => @role_id}.to_json
                      @feedback = JSON.parse(last_response.body)
                      @feedback_results = @mysql_client.query("SELECT sprint_timelines.* FROM sprint_timelines INNER JOIN contributors ON (sprint_timelines.contributor_id = contributors.id and sprint_timelines.diff='winner') INNER JOIN sprint_states ON sprint_states.id = contributors.sprint_state_id INNER JOIN role_states ON sprint_states.state_id = role_states.state_id INNER JOIN sprint_skillsets ON sprint_skillsets.sprint_id = sprint_states.sprint_id LEFT JOIN user_skillsets ON (user_skillsets.skillset_id = sprint_skillsets.skillset_id AND user_skillsets.active = 1) LEFT JOIN user_roles ON (user_roles.role_id = role_states.role_id AND user_roles.active = 1) WHERE user_skillsets.skillset_id = #{@skillset_id} AND user_roles.role_id = #{@role_id} AND contributors.user_id = #{@user_id} GROUP BY sprint_timelines.id")
                  end
                  it_behaves_like "ok"
                  it_behaves_like "user_feedback_contributor"
              end
          end

      end
      context "me" do
          context "unauthorized" do
              context "skillset" do
                  before(:each) do
                      get "/users/me/aggregate-contributors-received", {:skillset_id => @skillset_id}.to_json
                  end
                  it_behaves_like "unauthorized"
              end
              context "role" do
                  before(:each) do
                      get "/users/me/aggregate-contributors-received", {:role_id => @role_id}.to_json
                  end
                  it_behaves_like "unauthorized"
              end
              context "skillset&role" do
                  before(:each) do
                      get "/users/me/aggregate-contributors-received", {:skillset_id => @skillset_id, :role_id => @role_id}.to_json
                  end
                  it_behaves_like "unauthorized"
              end
          end
      end
  end
end
