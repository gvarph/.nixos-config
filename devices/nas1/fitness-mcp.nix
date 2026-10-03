{
  config,
  lib,
  pkgs,
  ...
}: let
  stateDir = "/var/lib/garmin-mcp";
  hardening = {
    Restart = "on-failure";
    ProtectSystem = "strict";
    ProtectHome = true;
    PrivateTmp = true;
    NoNewPrivileges = true;
    RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
  };
  # Read-only Garmin tools: every get_* plus two lookups; no writes or downloads.
  garminReadTools = [
    "count_activities"
    "search_foods"
    "get_acclimation"
    "get_activities"
    "get_activities_by_date"
    "get_activities_fordate"
    "get_activity"
    "get_activity_exercise_sets"
    "get_activity_fit_data"
    "get_activity_fit_messages"
    "get_activity_gear"
    "get_activity_hr_in_timezones"
    "get_activity_power_in_timezones"
    "get_activity_splits"
    "get_activity_split_summaries"
    "get_activity_typed_splits"
    "get_activity_types"
    "get_activity_weather"
    "get_adhoc_challenges"
    "get_all_day_events"
    "get_all_day_stress"
    "get_available_badge_challenges"
    "get_badge_challenges"
    "get_blood_pressure"
    "get_body_battery"
    "get_body_battery_events"
    "get_body_composition"
    "get_calendar_events"
    "get_course_details"
    "get_courses"
    "get_custom_foods"
    "get_custom_food_serving_units"
    "get_cycling_ftp"
    "get_daily_steps"
    "get_daily_weigh_ins"
    "get_device_alarms"
    "get_device_last_used"
    "get_devices"
    "get_device_settings"
    "get_device_solar_data"
    "get_earned_badges"
    "get_endurance_score"
    "get_energy_balance"
    "get_fitnessage_data"
    "get_floors"
    "get_full_name"
    "get_garmin_coach_workouts"
    "get_gear"
    "get_goals"
    "get_heart_rates"
    "get_heart_rates_summary"
    "get_heart_rate_zones"
    "get_hill_score"
    "get_hrv_data"
    "get_hrv_trend"
    "get_hydration_data"
    "get_inprogress_virtual_challenges"
    "get_lactate_threshold"
    "get_lifestyle_logging_data"
    "get_menstrual_calendar_data"
    "get_menstrual_data_for_date"
    "get_morning_training_readiness"
    "get_non_completed_badge_challenges"
    "get_nutrition_daily_food_log"
    "get_nutrition_daily_meals"
    "get_nutrition_daily_settings"
    "get_nutrition_summary_between_dates"
    "get_personal_record"
    "get_power_duration_curve"
    "get_pregnancy_summary"
    "get_primary_training_device"
    "get_progress_summary_between_dates"
    "get_race_predictions"
    "get_recovery_time_remaining"
    "get_respiration_data"
    "get_respiration_summary"
    "get_respiration_trend"
    "get_rhr_day"
    "get_running_tolerance"
    "get_running_tolerance_trend"
    "get_scheduled_workouts"
    "get_sleep_data"
    "get_sleep_summary"
    "get_sleep_summary_range"
    "get_spo2_data"
    "get_stats"
    "get_stats_and_body"
    "get_stats_range"
    "get_steps_data"
    "get_stress_data"
    "get_stress_summary"
    "get_training_effect"
    "get_training_load_balance"
    "get_training_load_trend"
    "get_training_plan_workouts"
    "get_training_readiness"
    "get_training_status"
    "get_unit_system"
    "get_user_profile"
    "get_userprofile_settings"
    "get_user_summary"
    "get_vo2max_trend"
    "get_weekly_intensity_minutes"
    "get_weekly_steps"
    "get_weekly_stress"
    "get_weigh_ins"
    "get_workout_by_id"
    "get_workouts"
  ];
in {
  # Garmin and Hevy MCP servers for Hermes: one shared loopback HTTP instance
  # each; credentials stay in these units, never in the hermes user's env.

  # One-time (and ~6-monthly) Garmin login with MFA: `garmin-mcp-auth`.
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "garmin-mcp-auth" ''
      sudo -u garmin-mcp env HOME=${stateDir} GARMINTOKENS=${stateDir}/tokens \
        ${lib.getExe' pkgs.garmin-mcp "garmin-mcp-auth"} "$@" \
        && sudo systemctl restart garmin-mcp
    '')
  ];

  users.users.garmin-mcp = {
    isSystemUser = true;
    group = "garmin-mcp";
    home = stateDir;
  };
  users.groups.garmin-mcp = {};

  systemd.services.garmin-mcp = {
    description = "Garmin Connect MCP server (Streamable HTTP, loopback)";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    wants = ["network-online.target"];
    environment = {
      HOME = stateDir;
      GARMINTOKENS = "${stateDir}/tokens";
      GARMIN_MCP_TRANSPORT = "streamable-http";
      GARMIN_MCP_HOST = "127.0.0.1";
      GARMIN_MCP_PORT = "8432";
      GARMIN_ENABLED_TOOLS = lib.concatStringsSep "," garminReadTools;
    };
    serviceConfig =
      hardening
      // {
        ExecStart = lib.getExe pkgs.garmin-mcp;
        User = "garmin-mcp";
        Group = "garmin-mcp";
        StateDirectory = "garmin-mcp";
        StateDirectoryMode = "0700";
      };
  };

  # hevy-mcp is stdio-only; mcp-proxy serves it over HTTP with one shared child.
  # The child gets only the API key (the env file also holds Garmin creds).
  systemd.services.hevy-mcp = {
    description = "Hevy MCP server (Streamable HTTP via mcp-proxy, loopback)";
    wantedBy = ["multi-user.target"];
    after = ["network-online.target"];
    wants = ["network-online.target"];
    serviceConfig =
      hardening
      // {
        ExecStart = let
          child = pkgs.writeShellScript "hevy-mcp-child" ''
            exec env -i HEVY_API_KEY="$HEVY_API_KEY" HEVY_MCP_TELEMETRY=0 \
              HOME="$HOME" ${lib.getExe pkgs.hevy-mcp}
          '';
        in "${lib.getExe pkgs.mcp-proxy} --transport streamablehttp --host 127.0.0.1 --port 8433 --pass-environment ${child}";
        EnvironmentFile = config.age.secrets.hevy2garmin_env.path;
        DynamicUser = true;
        RuntimeDirectory = "hevy-mcp";
        Environment = "HOME=/run/hevy-mcp";
      };
    restartTriggers = [config.age.secrets.hevy2garmin_env.file];
  };

  services.hermes-agent.mcpServers = {
    # Read-only filter is enforced server-side (GARMIN_ENABLED_TOOLS above).
    garmin.url = "http://127.0.0.1:8432/mcp";
    hevy = {
      url = "http://127.0.0.1:8433/mcp";
      tools.include = [
        "get-training-summary"
        "get-workouts"
        "get-workout"
        "get-workout-events"
        "get-routines"
        "get-routine"
        "search-routines"
        "get-routine-folder"
        "get-exercise-template"
        "search-exercise-templates"
        "get-exercise-history"
        "get-body-measurements"
        "get-body-measurement"
      ];
    };
  };
  systemd.services.hermes-agent = {
    wants = ["garmin-mcp.service" "hevy-mcp.service"];
    after = ["garmin-mcp.service" "hevy-mcp.service"];
  };
  systemd.services.hermes-backend = {
    wants = ["garmin-mcp.service" "hevy-mcp.service"];
    after = ["garmin-mcp.service" "hevy-mcp.service"];
  };
}
