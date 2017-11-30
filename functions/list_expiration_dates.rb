#!./bin/ruby

require 'bundler/setup'
require 'spaceship'
require 'slack/incoming/webhooks'
require 'time'
require 'json'

CERTIFICATE = "証明書"
MOBILEPROVISION = "プロビジョニングプロファイル"

# 有効期限が後何日で切れるか取得
def get_days_left(expiration_date)
  now = Time.now
  today = Time.local(now.year, now.month, now.day)
  diff = ((expiration_date - today) / 3600 / 24).ceil
end

# Slackに投稿するための準備
def prepare_for_posting(type, apps)
  if type == CERTIFICATE
    names = apps.map { |app| app.owner_name }
  elsif type == MOBILEPROVISION
    names = apps.map { |app| app.name }
  end
  
  expires = apps.map { |app| app.expires.to_s }
  days_left = expires.map { |expire|
    t = Time.parse(expire).to_time
    get_days_left(Time.local(t.year, t.month, t.day))
  }
  return names.zip(expires, days_left)
end

# 拡張子の取得
def get_file_extension(type)
  if type == CERTIFICATE
    return ".cer"
  elsif type == MOBILEPROVISION
    return ".mobileprovision"
  end
end


# main
if ARGV.length == 8
  channel = ARGV[0]
  username = ARGV[1]
  icon = ARGV[2]
  warning_day = ARGV[3]
  danger_day = ARGV[4]
  webhookurl = "https://#{ARGV[5]}"
  account_list = { ARGV[6] => ARGV[7] }
else
  exit 1
end

$slack = Slack::Incoming::Webhooks.new webhookurl, channel: channel, username: username, icon_emoji: icon

account_list.each { |id, pass|
  attachments = []
  attachment = {
    "text"   => "アカウント：#{id}",
    "color"  => "#000",
    "fields" => []
  }
  
  expired_attachment = {
    "text"   => "有効期限切れは以下です",
    "color"  => "#53bef8",
    "fields" => []
  }
  
  warning_attachment = {
    "text"   => "有効期限が近づいているのは以下です",
    "color"  => "warning",
    "fields" => []
  }
  
  danger_attachment = {
    "text"   => "有効期限が迫っているのは以下です！！",
    "color"  => "danger",
    "fields" => []
  }
  
  Spaceship::Portal.login(id, pass)
  cer_profile_list = { CERTIFICATE => Spaceship::Portal.certificate.all, MOBILEPROVISION => Spaceship::Portal.provisioning_profile.all }
  
  cer_profile_list.each() { |type, apps|
    file_extension = get_file_extension(type)
  
    infos = prepare_for_posting(type, apps)
    
    infos.each { |app|
      item = {
        "title" => "#{app[0]}(#{file_extension})",
        "value" => "後 #{app[2]}日 (有効期限：#{Time.parse(app[1]).to_time.strftime("%Y/%m/%d")})",
        "short" => true
      }
      
      if app[2] < 0
        expired_attachment["fields"].push(item)
      elsif app[2] < danger_day.to_i
        danger_attachment["fields"].push(item)
      elsif app[2] < warning_day.to_i
        warning_attachment["fields"].push(item)
      else
        attachment["fields"].push(item)
      end
    }
  }
  
  attachments.push(attachment).push(expired_attachment).push(warning_attachment).push(danger_attachment)
  
  # Slackに投稿
  $slack.post "#{account_list[0]}", attachments: attachments
}