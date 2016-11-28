#
# Copyright:: Copyright (c) 2016 GitLab Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module Logging
  class << self
    def parse_variables
      parse_udp_log_shipping
    end

    def parse_udp_log_shipping
      logging = Gitlab['logging']
      return unless logging['udp_log_shipping_host']

      Gitlab['remote_syslog']['enable'] ||= true
      Gitlab['remote_syslog']['destination_host'] ||= logging['udp_log_shipping_host']

      if logging['udp_log_shipping_port']
        Gitlab['remote_syslog']['destination_port'] ||= logging['udp_log_shipping_port']
        Gitlab['logging']['svlogd_udp'] ||= "#{logging['udp_log_shipping_host']}:#{logging['udp_log_shipping_port']}"
      else
        Gitlab['logging']['svlogd_udp'] ||= logging['udp_log_shipping_host']
      end

      %w{
        redis
        ci-redis
        nginx
        sidekiq
        ci-sidekiq
        unicorn
        ci-unicorn
        postgresql
        remote-syslog
        gitlab-workhorse
        mailroom
        mattermost
        gitlab-pages
        registry
        node_exporter
        prometheus
        redis_exporter
        gitlab_monitor
      }.each do |runit_sv|
        Gitlab[runit_sv.gsub('-', '_')]['svlogd_prefix'] ||= "#{Gitlab['node']['hostname']} #{runit_sv}: "
      end
    end
  end
end
