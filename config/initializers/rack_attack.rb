# frozen_string_literal: true

module Rack
  # Mitigating Bad Bots with Rack::Attack
  class Attack # rubocop:disable Metrics/ClassLength
    Rack::Attack.enabled = true

    # ========================================
    # SUSPICIOUS ENDPOINT ACCESS
    # ========================================

    SUSPICIOUS_PREFIX_PATHS = %w[
      /%
      /..
      /.aws
      /.env
      /.git
      /.github
      /.ssh
      /.well-known
      /_
      /_profiler
      /actuator
      /admin
      /administrator
      /ajax
      /application
      /backend
      /backup
      /bak
      /beta.
      /bin
      /C
      /cgi-bin
      /common
      /config.
      /configur
      /console
      /content
      /controller
      /data
      /dashboard
      /data
      /database
      /db
      /debug
      /default
      /deploy
      /download
      /dump
      /etc
      /ftp
      /graphql
      /html
      /http
      /id_
      /index.
      /install
      /jolokia
      /lib
      /login
      /manage
      /module
      /old
      /output
      /php
      /phpinfo
      /phpinfo.php
      /phpmyadmin
      /Release
      /rest
      /robots.txt
      /ROOT
      /roundcube
      /service
      /setup
      /setup.php
      /sitemap.xml
      /sql
      /ssl
      /temp.
      /test.
      /tmp.
      /tmui
      /upload.
      /uploads.
      /web.
      /webadmin
      /webapps.
      /website.
      /webtools
      /windows
      /wp-
      /wp-admin
      /wp-content
      /wp-login.php
      /www.
      /wwwroot.
      /xml
      /xmlrpc.php
    ].freeze

    SUSPICIOUS_SUFFIX_PATHS = %w[
      .7z
      .asp
      .aspx
      .bak
      .cgi
      .conf
      .config
      .db
      .dll
      .dump
      .exe
      .ini
      .jar
      .jsp
      .key
      .log
      .old
      .pem
      .php
      .ppk
      .properties
      .py
      .sh
      .sql
      .tar.gz
      .txt
      .zip
    ].freeze

    blocklist("block_suspicious_paths") do |req|
      SUSPICIOUS_SUFFIX_PATHS.any? { |path| req.path.end_with?(path) } ||
        SUSPICIOUS_PREFIX_PATHS.any? { |path| req.path.start_with?(path) }
    end

    # ========================================
    # WHITELIST LEGITIMATE SERVICES
    # ========================================

    # Safelist your own IP ranges (development/staging)
    safelist("allow_local_ips") do |req|
      request_ip = IPAddr.new(req.ip)

      ["127.0.0.1", "::1", "10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"].any? do |range|
        range_ip = IPAddr.new(range)
        range_ip.family == request_ip.family && range_ip.include?(request_ip)
      rescue IPAddr::AddressFamilyError, IPAddr::InvalidAddressError
        false
      end
    end

    # ========================================
    # RESPONSE CUSTOMIZATION
    # ========================================

    # Custom responses for different block types
    self.blocklisted_responder = lambda do |_env|
      [403, { "Content-Type" => "application/json" }, [JSON.generate({
                                                                       error: "Forbidden",
                                                                       message: "Bot access detected and blocked"
                                                                     })]]
    end

    self.throttled_responder = lambda do |_env|
      [429, { "Content-Type" => "application/json" }, [JSON.generate({
                                                                       error: "Too Many Requests",
                                                                       message: "Rate limit exceeded"
                                                                     })]]
    end

    # ========================================
    # 8. LOGGING AND MONITORING
    # ========================================

    # Log blocked requests
    ActiveSupport::Notifications.subscribe("rack.attack") do |_name, _start, _finish, _request_id, payload|
      req = payload[:request]

      case payload[:match_type]
      when :blocklist
        Rails.logger.warn "Rack::Attack BLOCKED #{req.ip} - #{payload[:matched]} - #{req.path} - #{req.user_agent}"
      when :throttle
        Rails.logger.warn "Rack::Attack THROTTLED #{req.ip} - #{payload[:matched]} - #{req.path} - #{req.user_agent}"
      when :safelist
        Rails.logger.info "Rack::Attack SAFELISTED #{req.ip} - #{payload[:matched]} - #{req.path}"
      end
    end

    # ========================================
    # HELPER METHODS
    # ========================================

    # Mark IP as blocked for escalation
    def self.mark_blocked_ip(ip)
      Rack::Attack.cache.write("blocked_#{ip}", true, expires_in: 1.hour)
    end
  end
end
