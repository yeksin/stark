#!/bin/bash
TAG=$( git clone -b v0.2.4-alpha https://github.com/eqlabs/pathfinder/ | cut -d '"' -f 4)
SSHCON=$(curl -s -4 ifconfig.co)
GREEN="\e[32m"
NC="\e[0m"
source $HOME/.profile
echo -e ''
curl -s https://api.testnet.run/logo.sh | bash && sleep 3
echo -e ''
sudo apt update
sudo apt full-upgrade -y

dependient () {
        if ( ! python3 -V ) > /dev/null 2>&1; then
                sudo apt install python3
        else
                echo "Python3 found."
        fi
        sudo apt install -y build-essential libssl-dev libffi-dev python3-dev
        sudo apt-get install libgmp-dev -y
        pip3 install fastecdsa -y
        sudo apt-get install -y pkg-config -y
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source $HOME/.cargo/env
        sudo apt install cargo -y
        rustup update stable
        source $HOME/.cargo/env
}       

github_clone () {
		cd $HOME
        git clone https://github.com/eqlabs/pathfinder.git
        cd $HOME/pathfinder
        git switch -c $TAG
}

api_request () {
        echo -e ''
        echo -e "\e[0;32mIn this step, you will need an endpoint, to get this, please open an İnfura or Alchemy account. And then enter the  Ethereum goerli or Ethereum mainnet endpoint link (HTTP) here then press [ENTER]..\e[0m"
		echo -e '\e[0;35m'
    if [ ! $API_NEED ]; then
		read -p "Enter your api: " API_NEED
		echo 'export API_NEED='\"${API_NEED}\" >> $HOME/.bash_profile
        echo -e  '\e[0m'
	fi
    source $HOME/.bash_profile
}

environment () {
        sudo apt install python3.8-venv -y
        cd $HOME/pathfinder/py
        python3 -m venv .venv
        source .venv/bin/activate
        PIP_REQUIRE_VIRTUALENV=true pip install --upgrade pip
        PIP_REQUIRE_VIRTUALENV=true pip install -r requirements-dev.txt
}


build () {
        cargo build --release --bin pathfinder
        cp ~/pathfinder/target/release/pathfinder /usr/bin/
}

run_node () {
        sudo tee <<EOF >/dev/null /etc/systemd/system/starknetd.service
[Unit]
Description=StarkNet

[Service]
User=$USER
WorkingDirectory=$HOME/pathfinder/py
VIRTUAL_ENV=$HOME/pathfinder/py/.venv/bin
Environment=PATH=$VIRTUAL_ENV/bin:$PATH
ExecStart=/usr/bin/pathfinder --ethereum.url $API_NEED --http-rpc='0.0.0.0:9545'
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable starknetd
sudo systemctl restart starknetd
}

info () {
    echo -e ${GREEN}"======================================================"${NC}
    LOG_NODE="journalctl -u starknetd.service -f -n 100"
    source $HOME/.profile
    echo -e "Check starknet node logs: ${GREEN}$LOG_NODE${NC}"
    echo -e ${GREEN}"======================================================"${NC}
}

process () {
        source $HOME/.profile
        source $HOME/.cargo/env
        dependient
        github_clone
        api_request
        environment
        build
        run_node
        info
}
process
