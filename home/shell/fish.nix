{
  config,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    fishPlugins.forgit
    fishPlugins.hydro
    fishPlugins.done
    jq
  ];

  programs.fish = {
    enable = true;
    shellInit = ''
      set fish_greeting
    '';

    plugins = [
      # fishPlugins.grc
      {
        name = "grc";
        src = pkgs.fishPlugins.grc.src;
      }

      # fishPlugins.fzf-fish
      {
        name = "fzf-fish";
        src = pkgs.fishPlugins.fzf-fish.src;
      }

      # fishPlugins.forgit
      {
        name = "forgit";
        src = pkgs.fishPlugins.forgit.src;
      }

      # fishPlugins.hydro
      {
        name = "hydro";
        src = pkgs.fishPlugins.hydro.src;
      }

      # fishPlugins.done
      {
        name = "done";
        src = pkgs.fishPlugins.done.src;
      }
    ];

    interactiveShellInit = ''
      set -g theme_nerd_fonts yes

      direnv hook fish | source
    '';

    functions = {
      mcd = {
        body = ''
          mkdir -p $argv[1]; and cd $argv[1]
        '';
        description = "Create a directory and change to it";
      };
      follow_pod_logs = {
        body = ''
          function follow_pod_logs -d "Follow logs from all containers in a specified pod"
            # Check if pod name is provided
            if test (count $argv) -lt 1
              echo "Usage: follow_pod_logs POD_NAME"
              return 1
            end

            # Extract pod name from arguments
            set pod_name $argv[1]

            # Get all container names in the pod
            set containers (kubectl get pod $pod_name -o json | jq -r '.spec.containers[].name')

            # Follow logs for each container
            for container in $containers
              echo "Following logs for container $container"
              kubectl logs -f $pod_name -c $container &
            end
          end
        '';
        description = "Follow logs from all containers in a specified pod";
      };
      starship_transient_prompt_func = {
        body = ''
               	function starship_transient_prompt_func
           		starship module character
          end
        '';
        description = "Starship transient prompt function";
      };
      dump_mongo_queries = {
        body = ''
          function dump_mongo_queries -d "Dump documents from a specified MongoDB collection in a given database"
            set dbname $argv[1]
            set collection $argv[2]
            set mongo_url $argv[3]

            if test -z "$dbname" -o -z "$collection"
              echo "Usage: dump_mongo_queries DB_NAME COLLECTION [MONGO_URL]"
              return 1
            end

            if test -n "$mongo_url"
              mongosh "$mongo_url" --quiet --eval "JSON.stringify(db.getSiblingDB(\"$dbname\").$collection.find().toArray())"
            else
              mongosh --quiet --eval "JSON.stringify(db.getSiblingDB(\"$dbname\").$collection.find().toArray())"
            end
          end
        '';
        description = "Dump documents from a MongoDB collection";
      };
    };
  };
}
