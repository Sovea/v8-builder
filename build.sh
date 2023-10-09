#!/bin/bash

# Enable "exit on error"
set -e

VERSION=$1
REPO=$2
PLATFORM=$3
SHORT_PLATFORM=$4
ARCH=$5
SHORT_ARCH=$6
BUILD_TYPE=$7

# Conf
if [[ "$SHORT_PLATFORM" = "linux" || "$SHORT_PLATFORM" = "android" ]]; then
    sudo apt-get update -y 1> nul
    sudo apt-get upgrade -y 1> nul
    sudo apt-get update -y 1> nul
    sudo apt-get upgrade -y 1> nul
    sudo apt-get install -y build-essential python-is-python3 libatomic1 1> nul
    sudo apt-get update -y 1> nul
    sudo apt-get upgrade -y 1> nul
    sudo apt-get update -y 1> nul
    sudo apt-get upgrade -y 1> nul
elif [ "$SHORT_PLATFORM" = "mac" ]; then
#    brew update
#    brew upgrade
    brew install pkg-config git curl wget python@3.8 xz zip ninja
fi

git config --global user.name "V8 Builder" 1> nul
git config --global user.email "v8.builder@localhost" 1> nul
git config --global core.autocrlf false 1> nul
git config --global core.filemode false 1> nul

cd $REPO
echo "=====[ Getting Depot Tools ]====="
if [ "$SHORT_PLATFORM" = "win" ]; then
    powershell -command "Invoke-WebRequest https://storage.googleapis.com/chrome-infra/depot_tools.zip -O depot_tools.zip" 1> nul
    7z x depot_tools.zip -o* 1> nul
    export DEPOT_TOOLS_WIN_TOOLCHAIN=0
else
    git clone -q https://chromium.googlesource.com/chromium/tools/depot_tools.git 1> nul
fi
export PATH=$(pwd)/depot_tools:$PATH
gclient
cd depot_tools
update_depot_tools
# Build

cd $REPO
mkdir v8
cd v8

echo "=====[ Fetching V8 ]====="
pwd
fetch v8
echo "target_os = ['$SHORT_PLATFORM']" >> .gclient
cd v8
pwd
git checkout $VERSION
if [[ "$SHORT_PLATFORM" = "linux" || "$SHORT_PLATFORM" = "android" ]]; then
    ./build/install-build-deps.sh --no-syms --no-nacl --no-prompt
fi
gclient sync

if [ "$SHORT_PLATFORM" = "linux" ]; then
./build/linux/sysroot_scripts/install-sysroot.py --arch=$SHORT_ARCH
fi

echo "=====[ Building V8 ]====="

ARGS=""
if [ "$SHORT_PLATFORM" = "win" ]; then
ARGS="is_clang=true use_lld=false"
sed -i 's/"-Wmissing-field-initializers",/"-Wmissing-field-initializers","-D_SILENCE_ALL_CXX20_DEPRECATION_WARNINGS",/' BUILD.gn
fi

if [ "$BUILD_TYPE" = "monolith" ]; then
python ./tools/dev/v8gen.py $ARCH -vv --no-goma -- $ARGS target_os=\"$SHORT_PLATFORM\" target_cpu=\"$SHORT_ARCH\" v8_target_cpu=\"$SHORT_ARCH\" is_component_build=false use_goma=false v8_monolithic=true use_custom_libcxx=false v8_enable_sandbox=false v8_enable_i18n_support=true v8_use_external_startup_data=false
else
python ./tools/dev/v8gen.py $ARCH -vv --no-goma -- $ARGS target_os=\"$SHORT_PLATFORM\" target_cpu=\"$SHORT_ARCH\" v8_target_cpu=\"$SHORT_ARCH\" is_component_build=false use_goma=false v8_monolithic=false use_custom_libcxx=false v8_enable_sandbox=false v8_enable_i18n_support=true v8_use_external_startup_data=false
fi
ninja -C out.gn/$ARCH -t clean 1> nul
ninja -C out.gn/$ARCH


# ZIP

cd $REPO
mkdir -p $REPO/v8_zip 1> nul
cp -r $REPO/v8/v8/include $REPO/v8_zip 1> nul

# Disable "exit on error"
set +e
find $REPO/v8/v8/out.gn/$ARCH -type f -maxdepth 1
find $REPO/v8/v8/out.gn/$ARCH/obj -type f -maxdepth 1
cp $REPO/v8/v8/out.gn/$ARCH/args.gn $REPO/v8_zip
cp $REPO/v8/v8/out.gn/$ARCH/icudtl.dat $REPO/v8_zip

cp $REPO/v8/v8/out.gn/$ARCH/*.exe $REPO/v8_zip
cp $REPO/v8/v8/out.gn/$ARCH/*.pdb $REPO/v8_zip
cp $REPO/v8/v8/out.gn/$ARCH/*.dll $REPO/v8_zip
cp $REPO/v8/v8/out.gn/$ARCH/*.lib $REPO/v8_zip

if [ $BUILD_TYPE = "monolith" ]; then
cp $REPO/v8/v8/out.gn/$ARCH/obj/libv8_monolith.a $REPO/v8_zip
cp $REPO/v8/v8/out.gn/$ARCH/obj/v8_monolith.lib $REPO/v8_zip
else
cp $REPO/v8/v8/out.gn/$ARCH/obj/libv8*.a $REPO/v8_zip
cp $REPO/v8/v8/out.gn/$ARCH/obj/v8*.lib $REPO/v8_zip
fi
cp $REPO/v8/v8/out.gn/$ARCH/obj/*.dylib $REPO/v8_zip
# Enable "exit on error"
set -e


if [ $SHORT_PLATFORM != "win" ]; then
zip -r v8_$PLATFORM.zip $REPO/v8_zip/* 1> nul
else
7z a v8_$PLATFORM.zip $REPO/v8_zip/* 1> nul
fi
