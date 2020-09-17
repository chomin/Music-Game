# carthage.sh
# Usage example: ./carthage.sh update --platform iOS

set -eu

export XCODE_XCCONFIG_FILE="$(readlink -f $(dirname $0))/Carthage/carthage_workaround_for_xcode12.xcconfig"
echo $XCODE_XCCONFIG_FILE
carthage "$@"
