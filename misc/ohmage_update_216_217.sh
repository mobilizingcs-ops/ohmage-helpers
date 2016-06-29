OHMAGE_VERSION=2.17.3
DB_PASS=\&\!sickly


# a place to store the flyway executable/libs
mkdir /opt/flyway

# a working directory!
cd /tmp

# download flyway executable, new compiled war file and the ohmage source (to obtain the flyway migrations)
wget http://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/3.2.1/flyway-commandline-3.2.1.tar.gz
wget https://github.com/ohmage/server/releases/download/v$OHMAGE_VERSION/app.war
wget wget https://github.com/ohmage/server/archive/v$OHMAGE_VERSION.tar.gz 

# extract flyway, placing contents in /opt/flyway
tar xf flyway-commandline-3.2.1.tar.gz --strip-components=1 -C /opt/flyway

# extract ohmage source, and move migrations
tar xf v$OHMAGE_VERSION.tar.gz
mv server-$OHMAGE_VERSION/db/migration/* /opt/flyway/sql/

# configure flyway to contact mysql db.
echo "flyway.url=jdbc:mysql://127.0.0.1:3306/ohmage
flyway.user=ohmage
flyway.password=$DB_PASS" > /opt/flyway/conf/flyway.conf

# baseline your ohmage schema if 2.16 -> 2.17 and you've never used flyway before.
/opt/flyway/flyway baseline -baselineVersion=3

# make sure you have a backup of your database before you try to upgrade!
mysqldump -uohmage -p$DB_PASS ohmage | gzip > /tmp/ohmage_db_$(date +"%m_%d_%Y").sql.gz

# migrate
/opt/flyway/flyway migrate

# assuming output from flyway migrate is successful:
service tomcat7 stop
rm -rf /var/lib/tomcat7/webapps/app
mv /tmp/app.war /var/lib/tomcat7/webapps/
service tomcat7 start