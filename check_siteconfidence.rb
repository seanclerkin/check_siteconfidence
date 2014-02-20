#!/usr/bin/env ruby

require "rubygems"
require "net/http"
require "uri"
require "json"
require 'getoptlong'

opts = GetoptLong.new(
  [ '--username', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--password', GetoptLong::REQUIRED_ARGUMENT ],
  [ '--label', GetoptLong::REQUIRED_ARGUMENT ],
)

username = nil
password = nil
label = nil
result_code = nil
time_taken = nil
time_ran = nil
result_codes = Hash.new

# Map Site Confidence result codes to Nagios exit codes and definitions
result_codes = { "0"   => [0, "Test in progress"],
                 "1"   => [0, "Site OK"],
                 "2"   => [1, "No Connection To Server For Object"],
                 "3"   => [1, "Missing Object"],
                 "4"   => [2, "Page Access Denied"],
                 "5"   => [2, "Web Page Download Timed Out"],
                 "6"   => [2, "Web Page Server Error"],
                 "7"   => [2, "Unknown Web Page Error"],
                 "8"   => [2, "Bad HTTP Headers"],
                 "9"   => [2, "Obscene Word"],
                 "10"  => [2, "Could Not Connect To Web Server"],
                 "11"  => [1, "Object Download Timed Out"],
                 "12"  => [1, "Access To Object Denied"],
                 "13"  => [1, "Object Server Error"],
                 "14"  => [1, "Bad Object Headers"],
                 "15"  => [2, "Web Page Download Failed"],
                 "16"  => [2, "DNS Error"],
                 "17"  => [1, "Object DNS Failure"],
                 "18"  => [2, "Server Closed Connection"],
                 "19"  => [1, "Server Closed Connection On Object"],
                 "20"  => [2, "Application Content Error"],
                 "21"  => [2, "SiteCon Error Found"],
                 "22"  => [2, "No HTML"],
                 "23"  => [2, "Expected Phrase Not Found"],
                 "24"  => [2, "Page Size Too Small"],
                 "25"  => [2, "Page Size Too Large"],
                 "26"  => [2, "Redirect Expired"],
                 "27"  => [1, "Redirect Expired On Component"],
                 "28"  => [1, "Web Server Connection Failed For Object"],
                 "29"  => [1, "No Content For An Object"],
                 "30"  => [2, "Customer Specific Script Error"],
                 "31"  => [2, "Customer Specific Phrase Found"],
                 "32"  => [2, "Customer Specific Maintenance Page"],
                 "33"  => [2, "Customer Specific Error Page"],
                 "34"  => [2, "Customer Specific Search Result Time-Out"],
                 "35"  => [2, "Customer Specific Login Failure"],
                 "36"  => [2, "Customer Specific ODBC Error"],
                 "40"  => [0, "Dummy Page Test"],
                 "41"  => [2, "DNS Timeout"],
                 "42"  => [1, "Object DNS Timeout"],
                 "43"  => [2, "Web Server Refused Connection"],
                 "44"  => [1, "Web Server Refused Connection For Object"],
                 "45"  => [2, "Data Start Threshold Exceeded"],
                 "46"  => [1, "Data Start Threshold Exceeded For Object"],
                 "47"  => [2, "Could Not Write Request"],
                 "48"  => [1, "Could Not Write Request For Object"],
                 "49"  => [2, "Number of missing objects reached"],
                 "100" => [3, "Network Backbone Outage"],
                 "101" => [3, "Site Confidence Null Result"],
                 "102" => [3, "Customer Null Test"],
                 "103" => [3, "Script Failure"],
                 "104" => [3, "JavaScript Execution Timeout Exceeded"],
                 "250" => [2, "XML Validation Syntax Error"],
                 "251" => [2, "XML Schema/DTD check failed"],
                 "253" => [2, "JSON Validation Syntax Error"],
                 "260" => [1, "SSL Certificate Error"],
                 "261" => [1, "SSL Certificate Error For Object"],
                 "262" => [1, "SSL Certificate Time Error"],
                 "263" => [1, "SSL Certificate Time Error For Object"],
                 "264" => [1, "SSL Certificate Verification Error"],
                 "265" => [1, "SSL Certificate Verification Error For Object"],
                 "266" => [1, "SSL Certificate Unknown Error"],
                 "267" => [1, "SSL Certificate Unknown Error for Object"],
                 "270" => [2, "NTLM authentication error"],
                 "271" => [2, "Specified Phrase Found"],
                }

unless ARGV.count > 0
  puts "Usage: check_siteconfidence.rb --username <username> --password <password> --label <label>"
  exit 3
end

opts.each do |opt, arg|
  case opt
  when '--help'
      puts "Usage: check_siteconfidence.rb --username <username> --password <password> --label <label of the test to check>"
      exit 0
    when '--username'
      username = arg
    when '--password'
      password = arg
    when '--label'
      label = arg
  end
end

def request_json(url)
  uri = URI.parse(url)
  https = Net::HTTP.new(uri.host, uri.port)
  https.verify_mode = OpenSSL::SSL::VERIFY_NONE
  https.use_ssl = true
  request = Net::HTTP::Get.new(uri.request_uri)
  response = https.request(request)
  json = JSON.parse(response.body)
  return json
end

api_key = request_json("https://api.siteconfidence.co.uk/current/username/#{username}/password/#{password}/Format/JSON/")["Response"]["ApiKey"]["Value"]

account_id = request_json("https://api.siteconfidence.co.uk/current/#{api_key}/Format/JSON")["Response"]["Account"]["AccountId"]

json = request_json("https://api.siteconfidence.co.uk/current/#{api_key}/Return/%5BAccount%5BUserJourneys%5BUserJourney%5BId%2CLabel%2CLastTestGmtTimestamp%2CLastTestDownloadSpeed%2CCurrentStatus%2CResultCode%5D%5D%5D%5D/AccountId/#{account_id}/ScriptType/0/Format/JSON/")

user_journeys = json["Response"]["Account"]["UserJourneys"]["UserJourney"]

user_journeys.each do |user_journey|
  if label == user_journey["Label"]
   result_code = user_journey["ResultCode"]
   time_taken = user_journey["LastTestDownloadSpeed"]
   time_ran = user_journey["LastTestGmtTimestamp"]
  end
end

exit_code = result_codes[result_code][0]
result_string = result_codes[result_code][1]

case exit_code
  when 0
    puts "OK: Test of #{label} took #{time_taken}s, result code #{result_code} - #{result_string} | time_taken=#{time_taken}"
    exit exit_code
  when 1
    puts "WARNING: Test of #{label} took #{time_taken}s, result code #{result_code} - #{result_string} | time_taken=#{time_taken}"
    exit exit_code
  when 2
    puts "CRITICAL: Test of #{label} took #{time_taken}s, result code #{result_code} - #{result_string} | time_taken=#{time_taken}"
    exit exit_code
end