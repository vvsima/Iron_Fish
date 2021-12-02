#!/bin/bash
# Default variables
function="install"

# Options
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/colors.sh) --
option_value(){ echo "$1" | sed -e 's%^--[^=]*=%%g; s%^-[^=]*=%%g'; }
while test $# -gt 0; do
	case "$1" in
	-h|--help)
		. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)
		echo
		echo -e "${C_LGn}Functionality${RES}: the script installs an Iron Fish node"
		echo
		echo -e "${C_LGn}Usage${RES}: script ${C_LGn}[OPTIONS]${RES}"
		echo
		echo -e "${C_LGn}Options${RES}:"
		echo -e "  -h, --help            show the help page"
		echo -e "  -u, --update          update the node"
		echo
		echo -e "${C_LGn}Useful URLs${RES}:"
		echo -e "https://github.com/SecorD0/Aleo/blob/main/multi_tool.sh — script URL"
		echo -e "https://teletype.in/@letskynode/Iron_Fish_RU — Russian-language guide"
		echo -e "https://t.me/letskynode — node Community"
		echo
		return 0 2>/dev/null; exit 0
		;;
	-u|--update)
		function="update"
		shift
		;;
	*|--)
		break
		;;
	esac
done

# Functions
printf_n(){ printf "$1\n" "${@:2}"; }
install() {
	sudo apt update
	sudo apt upgrade -y
	if [ ! -n "$iron_fish_moniker" ]; then
		printf_n "${C_LGn}Enter a node moniker${RES}"
		. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/miscellaneous/insert_variable.sh) -n iron_fish_moniker
	fi
	if [ ! -n "$iron_fish_wallet_name" ]; then
		printf_n "${C_LGn}Enter a wallet name${RES}"
		. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/miscellaneous/insert_variable.sh) -n iron_fish_wallet_name
	fi
	sudo apt install wget jq bc build-essential -y
	. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/installers/docker.sh)
	docker run -dit --name iron_fish_node --restart always --network host --volume $HOME/.ironfish:/root/.ironfish ghcr.io/iron-fish/ironfish:latest
	. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/miscellaneous/insert_variable.sh) -n ifn_log -v "docker logs iron_fish_node -fn 100" -a
	. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/miscellaneous/insert_variable.sh) -n if_node_info -v ". <(wget -qO- https://raw.githubusercontent.com/SecorD0/Iron_Fish/main/node_info.sh) -l RU 2> /dev/null" -a
	. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/miscellaneous/insert_variable.sh) -n ironfish -v "docker exec -it iron_fish_node ironfish" -a
	docker exec -it iron_fish_node ironfish config:set nodeName $iron_fish_moniker
	docker exec -it iron_fish_node ironfish config:set blockGraffiti $iron_fish_moniker
	docker restart iron_fish_node
	printf_n "${C_LGn}Waiting 20 seconds...${RES}"
	sleep 20
	if ! docker exec -it iron_fish_node ironfish accounts:list | grep -q $iron_fish_wallet_name && [ ! -f $HOME/iron_fish_${iron_fish_wallet_name}.txt ]; then
		docker exec -it iron_fish_node ironfish accounts:create $iron_fish_wallet_name
		docker exec -it iron_fish_node ironfish accounts:export $iron_fish_wallet_name "iron_fish_${iron_fish_wallet_name}.txt"
		docker cp iron_fish_node:/usr/src/app/iron_fish_${iron_fish_wallet_name}.txt $HOME/iron_fish_${iron_fish_wallet_name}.txt
	elif [ -f $HOME/iron_fish_${iron_fish_wallet_name}.txt ]; then
		docker cp $HOME/iron_fish_${iron_fish_wallet_name}.txt iron_fish_node:/usr/src/app/iron_fish_${iron_fish_wallet_name}.txt
		docker exec -dit iron_fish_node ironfish accounts:import "iron_fish_${iron_fish_wallet_name}.txt"
	fi
	docker exec -it iron_fish_node ironfish accounts:use $iron_fish_wallet_name
	printf_n "${C_LGn}Done!${RES}"
	. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)
	printf_n "
The node was ${C_LGn}started${RES}.
Remember to save this file: ${C_LR}$HOME/iron_fish_${iron_fish_wallet_name}.txt${RES}

\tv ${C_LGn}Useful commands${RES} v

To view info about the node: ${C_LGn}if_node_info${RES}
Alias for node commands execution: ${C_LGn}ironfish${RES}
To view the node log: ${C_LGn}ifn_log${RES}
To restart the node: ${C_LGn}docker restart iron_fish_node${RES}
"
}
update() {
	printf_n "${C_LGn}Checking for update...${RES}"
	status=`docker pull ghcr.io/iron-fish/ironfish:latest`
	if ! grep -q "Image is up to date for" <<< "$status"; then
		printf_n "${C_LGn}Updating...${RES}"
		if docker ps -a | grep -q iron_fish_node; then
			docker stop iron_fish_node
			docker rm iron_fish_node
			docker run -dit --name iron_fish_node --restart always --network host --volume $HOME/.ironfish:/root/.ironfish ghcr.io/iron-fish/ironfish:latest
			printf_n "${C_LGn}The node was successfully updated!${RES}"
		fi
		if docker ps -a | grep -q iron_fish_miner; then
			local threads=`docker inspect iron_fish_miner | jq -r ".[0].Config.Cmd[2]"`
			docker stop iron_fish_miner
			docker rm iron_fish_miner
			docker run -dit --name iron_fish_miner --restart always --network host --volume $HOME/.ironfish:/root/.ironfish ghcr.io/iron-fish/ironfish:latest miners:start -t $threads
			printf_n "${C_LGn}The miner was successfully updated!${RES}"
		fi
	else
		printf_n "${C_LGn}Node version is current!${RES}"
	fi
}

# Actions
sudo apt install wget jq -y &>/dev/null
. <(wget -qO- https://raw.githubusercontent.com/SecorD0/utils/main/logo.sh)
$function
