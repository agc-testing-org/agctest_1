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
