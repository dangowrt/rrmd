#!/usr/bin/ucode -S

push(REQUIRE_SEARCH_PATH, '/usr/share/rrmd/*.uc');

global.nl80211 = require("nl80211");
global.ubus = require('ubus');
global.uloop = require("uloop");
global.fs = require('fs');

const rrm_methods = {
	phys: {
		call: function(msg) {
			return global.phy.status();
		}
	},

	interfaces: {
		call: function(msg) {
			return global.local.status();
		}
	},

	stations: {
		call: function(msg) {
			return global.station.list(msg);
		}
	},

	status: {
		call: function(msg) {
			return global.station.status();
		}
	},

	command: {
		call: function(msg) {
			return global.command.handle(msg);
		}
	},

	get_beacon_request: {
		call: function(msg) {
			let val = global.station.list(msg);
			return val?.beacon_report || {};
		}
	},

	policy: {
		call: function(msg) {
			return global.policy.status(msg);
		},
	},

	reload: {
		call: function(msg) {
			global.config.init();
			for (let module in [ 'local', 'station' ])
				global[module].reload();
		},
	},

	scan_dump: {
		call: function(msg) {
			return global.scan.beacons;
		},
	},
};

function start() {
	try {
		global.uci = require('uci').cursor();
		global.ubus.conn = global.ubus.connect(null, 60);

		for (let module in [ 'config', 'event', 'phy', 'scan', 'neighbor', 'local', 'station', 'command', 'policy' ]) {
			printf('loading ' + module + '\n');
			global[module] = require(module);
			if (exists(global[module], 'init'))
				global[module].init();
		}
		global.ubus.conn.publish('rrm', rrm_methods);
	} catch(e) {
                printf('exception %.J %.J\n', e, e.stacktrace[0].context);
	}
};

start();
uloop.run();
