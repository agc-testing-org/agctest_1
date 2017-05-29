require 'spec_helper'
require 'api_helper'

describe "/teams" do

    fixtures :users

    before(:all) do
        @CREATE_TOKENS=true
    end

    shared_examples_for "teams" do
        it "should return id" do
            @team_results.each_with_index do |team_result,i|
                expect(@teams[i]["id"]).to eq(team_result["id"])
            end
        end
        it "should return name" do
            @team_results.each_with_index do |team_result,i|
                expect(@teams[i]["name"]).to eq(team_result["name"])
            end                                                     
        end 
        it "should return owner" do
            @team_results.each_with_index do |team_result,i|
                expect(@teams[i]["name"]).to eq(team_result["name"])
            end                                                    
        end 
    end


    describe "POST /" do
        before(:each) do
            @name = "NEW TEAM"
        end
        context "valid fields" do
            before(:each) do
                post "/teams", { :name => @name }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @team_results = @mysql_client.query("select * from teams")
                @teams = [JSON.parse(last_response.body)]
            end
            it_behaves_like "teams"

            context "user_teams" do
                before(:each) do
                    @user_team_result = @mysql_client.query("select * from user_teams").first
                end
                it "saves owner as sender_id" do
                    expect(@user_team_result["sender_id"]).to eq(@user)
                end
                it "saves owner as user_id" do
                    expect(@user_team_result["user_id"]).to eq(@user)
                end 
                it "saves accepted as true" do
                    expect(@user_team_result["accepted"]).to eq 1 
                end
            end
        end
        context "invalid fields" do
            context "name < 5 char"
            before(:each) do
                post "/teams", { :name => "1234" }.to_json, {"HTTP_AUTHORIZATION" => "Bearer #{@non_admin_w7_token}"}
                @team_results = @mysql_client.query("select * from teams")
                @error = JSON.parse(last_response.body)
            end
            it "should not save the result" do
                expect(@team_results.count).to eq(0)
            end
            it "should return error message" do
                expect(@error["error"]).to eq("Please enter a more descriptive team name")
            end
        end
    end
end
