#!/bin/bas


RUBY_VERSION=1.9.3-p484
OPT_INSTALL_PATH=/opt/DVLA/vcloud-management-tools
APP_NAME="vcloud-create-vapp"

# chicken and egg, need to fix this.
# bundler is required here
export PATH=/opt/ruby-local-$RUBY_VERSION/bin:$PATH
gem install bundler

#disinfect work areas
TIMESTAMP=$( date +%s)
BUILD_DIR=$PWD/build
rm -rf $BUILD_DIR
mkdir $BUILD_DIR

INSTALL_DIR=$PWD/install
rm -rf $INSTALL_DIR
mkdir $INSTALL_DIR

OUTPUT_DIR=$PWD/output
rm -rf $OUTPUT_DIR
mkdir $OUTPUT_DIR

#BUILD
#Fix environment
DEPENDS="ruby-local-$RUBY_VERSION"
export PATH=/opt/$DEPENDS/bin:$PATH

git clone https://github.com/dvla/vcloud-management-tools.git $INSTALL_DIR/$OPT_INSTALL_PATH

cd $INSTALL_DIR/$OPT_INSTALL_PATH
rm -rf .git #remove git files
bundle install --deployment --binstubs
bundle package --all

#make symlink into ./usr/bin
rm -f $INSTALL_DIR/usr/bin/$APP_NAME
mkdir -p $INSTALL_DIR/usr/bin/
cd $INSTALL_DIR
ln -s $OPT_INSTALL_PATH/bin/$APP_NAME usr/bin/$APP_NAME
cd -

#make rpm package
fpm -s dir -t rpm -n $APP_NAME -v 1.0.$TIMESTAMP -d $DEPENDS -C $INSTALL_DIR -p $OUTPUT_DIR .

#tidy up
rm -rf $INSTALL_DIR
rm -rf $BUILD_DIR