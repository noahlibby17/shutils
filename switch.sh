#!/bin/zsh

# set grep var
GREP_VAR=${1:-noah}
HEAD_LIM=10
# Declare prompt
MENUPROMPT='Choose branch to switch to: '
# Declare options array
OPTIONS=($(git branch --sort=-committerdate | grep $GREP_VAR | head -n 7 | cut -c 3-))

# Menu function
function MENU() {

	# COLORS
	GRAY="$(tput setaf 0; tput bold)"
	RED="$(tput setaf 1; tput bold)"
	GREEN="$(tput setaf 2; tput bold)"
	YELLOW="$(tput setaf 3; tput bold; tput smul)"
	BLUE="$(tput setaf 4; tput bold)"
	MAGENTA="$(tput setaf 5; tput bold)"
	CYAN="$(tput setaf 6; tput bold)"
	WHITE="$(tput setaf 7; tput bold)"
	EOS="$(tput sgr0)"	
	# MENU
	MENUPROMPT=$1
	DIV="===================="
	ARROW="$(tput setaf 3; tput bold)"
	INDICATOR="-->"
	SELECTED=1
	OPTIONS=(${@:2})
	LENGTH=${#OPTIONS[@]}

	# FUNCTIONS
	PRINT_MENU() {
		# Runs clear to prevent infinite scroll when choosing
		clear
		# Displays menu header
		echo -e "$BLUE$MENUPROMPT$EOS"
		echo -e "$BLUE$DIV$EOS"
		# Displays menu options
		for (( i=1;i<=${#OPTIONS[@]};i++ ))
		do
			if [[ $SELECTED -eq $i ]]
			# Renders current option in bold
			then
				OPT=${OPTIONS[$i]}
				echo -e "\n  $ARROW$INDICATOR$EOS $GREEN$OPT$EOS"
			# Renders other options
			else
				OPT=${OPTIONS[$i]}
				echo -e "\n$GRAY$OPT$EOS"
			fi
		done
		# Displays menu footer
		echo -e "\n$BLUE$DIV$EOS"
	}

	PRINT_MENU	
	# Reads user input // Navigation
	while read -rsk1 input
	do
    case $input in
      "A")
        if [[ $SELECTED -lt 2 ]]
        then
          SELECTED=$(($LENGTH))
        else
          SELECTED=$(($SELECTED - 1))
        fi
        PRINT_MENU
       ;;
      "B")
        if [[ $SELECTED -gt $(($LENGTH - 1)) ]]
        then
          SELECTED=1
        else
          SELECTED=$(($SELECTED + 1))
        fi
        PRINT_MENU
       ;;
      # Returns selected option
      "
") return $(($SELECTED)) ;;
    esac
  done
}

# Call the function and pass the arguments
MENU $MENUPROMPT $OPTIONS # w/o quotes

# Extract the selected option
RESULT=${OPTIONS[$?]}

echo "\nSwitching to branch: $RESULT"

git switch $RESULT
