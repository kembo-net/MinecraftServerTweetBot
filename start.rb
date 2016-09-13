require 'twitter'

client = Twitter::REST::Client.new do |config|
    config.consumer_key        = "APP_CONSUMER_KEY"
    config.consumer_secret     = "APP_CONSUMER_SECRET"
    config.access_token        = "YOUR_ACCESS_TOKEN"
    config.access_token_secret = "YOUR_ACCESS_TOKEN_SECRET"
end

#サーバーを起動するコマンド(好きなバージョン情報を入れてね)
cmd = 'java -Xms1024M -Xmx1024M -jar minecraft_server.x.x.x.jar nogui'
#ツイートする時に共通して利用するタグ
tag_str = " #TAG_NAME"

IO.popen(cmd) do |o|
  #コマンドの実行結果を逐次解析
  o.each do |new_log|
    puts new_log.chomp!
    if new_log =~ /^\[([0-9:]+)\] \[Server thread\/INFO\]: (.*)/
      time = $1
      new_log = $2
      case new_log
      when /^Done/
        client.update("サーバーが起動しました(#{time})"+tag_str)
      when /^Stopping t/
        client.update("サーバーを終了しました(#{time})"+tag_str)
      when /^<(\w+)> tweet (.*)$/ #ツイートコマンド
        main_text = $2
        sub_text  = ' (' + $1 + ')' + tag_str
        text_len  = main_text.length + sub_text.length
        if text_len > 140
          client.update(main_text[0...(140 - text_len - 2)] + sub_text)
        else
          client.update(main_text + sub_text)
        end
      when /^(\w+) (.*)$/ #その他プレイヤーにまつわるメッセージ
        ply_name = $1
        new_log = $2
        send_message = lambda { |message|
          message = ply_name + ' ' + message + '(' + time + ')' + tag_str
          puts message
          client.update(message)
        }
        text = case new_log
        when /joined the game$/ then "がログインしました"
        when /left the game$/ then "がログアウトしました"
        when /^was squashed/ then "が圧死しました"
        when /^was pricked/ then "がサボテンの針で死亡しました"
        when /^was killed by magic/ then "が魔法によって死亡しました"
        when /to escape (\w+)/ then "が#{$1}に追われて死亡しました"
        when /(?:by|fighting) (\w+)/ then "が#{$1}に殺されました"
        when /^drowned/ then "が溺死しました"
        when /^was shot by arrow/ then "が罠にかかって死亡しました"
        when /^(blew up|was blown up)/ then "が爆死しました"
        when /^(fell into a patch of fire)/ then "が焼死しました"
        when /^(fell|hit the ground)/ then "が転落死しました"
        when /^tried/ then "が溶岩に落ちて死亡しました"
        when /^died/ then "が突然死しました"
        when /^suffocated/ then "が窒息死しました"
        when /^withered/ then "が衰弱死しました"
        end
        send_message.call(text) unless text.nil?
      end
    end
  end
end

