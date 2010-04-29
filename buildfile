# Generated by Buildr 1.3.5, change to your liking
# Version number for this release
#VERSION_NUMBER = `grep Version: candlepin.spec`.split()[1]
#RELEASE_NUMBER = `grep Release: candlepin.spec`.split()[1]
VERSION_NUMBER = 0.4
RELEASE_NUMBER = 1
# Group identifier for your projects
GROUP = "candlepin.client"
COPYRIGHT = ""

#############################################################################
# DEPENDENCIES
#############################################################################

RESTEASY = [group('jaxrs-api', 
                  'resteasy-jaxrs',
                  'resteasy-jaxb-provider', 
                  'resteasy-jettison-provider', 
                  'resteasy-guice', 
                  :under => 'org.jboss.resteasy',
                  :version => '1.2.1.GA'), 
            'javax.persistence:persistence-api:jar:1.0',
            'xalan:xalan:jar:2.6.0',
            'org.scannotation:scannotation:jar:1.0.2',
            'org.codehaus.jettison:jettison:jar:1.1',
            'commons-httpclient:commons-httpclient:jar:3.1',
             'org.slf4j:slf4j-api:jar:1.5.8',
             'org.slf4j:slf4j-log4j12:jar:1.4.2',
             'org.freemarker:freemarker:jar:2.3.15' ]

JACKSON = [group('jackson-core-lgpl', 
                 'jackson-mapper-lgpl', 
                 'jackson-jaxrs',
                 :under => 'org.codehaus.jackson',
                 :version => '1.4.1')]
JUNIT = ['junit:junit:jar:4.5', 'org.mockito:mockito-all:jar:1.8.1']
LOG4J = 'log4j:log4j:jar:1.2.14'

COMMONS = ['commons-beanutils:commons-beanutils:jar:1.7.0',
           'commons-codec:commons-codec:jar:1.4',
           'commons-cli:commons-cli:jar:1.2',
           'commons-pool:commons-pool:jar:1.2',
           'commons-collections:commons-collections:jar:3.1',
           'commons-io:commons-io:jar:1.3.2',
           'commons-logging:commons-logging:jar:1.1.1']
JDOM = 'jdom:jdom:jar:1.0'
DOM4J = ['dom4j:dom4j:jar:1.6.1']
GETTEXT_COMMONS = 'org.xnap.commons:gettext-commons:jar:0.9.6'

CHECKSTYLE = ['checkstyle:checkstyle:jar:5.0',
              'antlr:antlr:jar:2.7.6',
              'com.google.collections:google-collections:jar:0.9',
              COMMONS]


BOUNCYCASTLE = group('bcprov-jdk16', 'bcpg-jdk16', :under=>'org.bouncycastle', :version=>'1.44')

#############################################################################
# REPOSITORIES
#
# Specify Maven 2.0 remote repositories here, like this:
repositories.remote << "http://www.ibiblio.org/maven2/"
repositories.remote << "http://repository.jboss.com/maven2/"
repositories.remote << "http://gettext-commons.googlecode.com/svn/maven-repository/"

#############################################################################
# PROJECT BUILD
#############################################################################
desc "Candlepin Client Project"
define "candlepin.client" do

  #
  # project info
  #
  project.version = VERSION_NUMBER
  project.group = GROUP
  manifest["Implementation-Vendor"] = COPYRIGHT

  #
  # eclipse settings
  # http://buildr.apache.org/more_stuff.html#eclipse
  #
  eclipse.natures 'org.eclipse.jdt.core.javanature'
  eclipse.natures 'net.sf.eclipsecs.core.CheckstyleNature'
  eclipse.builders 'org.eclipse.jdt.core.javabuilder'
  eclipse.builders 'net.sf.eclipsecs.core.CheckstyleBuilder'

  # download the stuff we do not have in the repositories
  download artifact('com.wideplay.warp:warp-persist:jar:2.0-20090214') => 'http://jmrodri.fedorapeople.org/ivy/candlepin/com/wideplay/warp/warp-persist/2.0-20090214/warp-persist-2.0-20090214.jar'

  # Resource Substitution
  resources.filter.using 'version'=>VERSION_NUMBER,
        'release'=>RELEASE_NUMBER
  
  #
  # building
  #
  resources.from _('po/classes')
  compile.options.target = '1.6'
  compile.with COMMONS, RESTEASY, LOG4J, BOUNCYCASTLE, JDOM, DOM4J, JACKSON, GETTEXT_COMMONS
 
  #
  # testing
  #
  test.resources.filter.using 'version'=>VERSION_NUMBER,
        'release'=>RELEASE_NUMBER
  #test.setup do |task|
  #  filter('src/main/resources/META-INF').into('target/classes/META-INF').run
  #end
  test.with COMMONS, RESTEASY, JUNIT, LOG4J, BOUNCYCASTLE, JDOM, DOM4J, GETTEXT_COMMONS

  #
  # javadoc projects
  #
  javadoc

  package(:jar, :id=>'candlepin-client').clean.include 'target/classes/org/fedoraproject/candlepin/client', :path=>"org/fedoraproject/candlepin/"  
  

  #
  # CHECKSTYLE task, a Buildr plugin would be better, but this is faster
  #
  task :checkstyle => compile do
    begin
      ant('checkstyle') do |ant|
        rm_rf 'reports/checkstyle_report.xml'
        mkdir_p 'reports'

        ant.taskdef :resource=>"checkstyletask.properties",
          :classpath=>Buildr.artifacts(CHECKSTYLE).each(&:invoke).map(&:name).join(File::PATH_SEPARATOR)

        # check the main src
        ant.checkstyle :config=>"buildconf/checkstyle.xml",
                       :classpath=>Buildr.artifacts(CHECKSTYLE, JDOM, RESTEASY).each(&:invoke).map(&:name).join(File::PATH_SEPARATOR) do


          ant.classpath :path=>_('target/classes')
          ant.formatter :type=>'plain'
          ant.formatter :type=>'xml', :toFile=>"reports/checkstyle_report.xml"

          ant.property :key=>'javadoc.method.scope', :value=>'public'
          ant.property :key=>'javadoc.type.scope', :value=>'package'
          ant.property :key=>'javadoc.var.scope', :value=>'package'
          ant.property :key=>'javadoc.lazy', :value=>'false'
          ant.property :key=>'javadoc.missing.param', :value=>'true'
          ant.property :key=>'checkstyle.cache.file', :value=>'target/checkstyle.cache.src'
          ant.property :key=>'checkstyle.header.file', :value=>'buildconf/LICENSE.txt'

          ant.fileset :dir=>"src/main/java", :includes=>'**/*.java', :excludes=>'**/OIDUtil.java'
        end

        # check the test src
        ant.checkstyle :config=>"buildconf/checkstyle.xml" do

          ant.classpath :path=>_('target/test/classes')
          ant.formatter :type=>'plain'
          ant.formatter :type=>'xml', :toFile=>"reports/checkstyle_report.xml"

          ant.property :key=>'javadoc.method.scope', :value=>'nothing'
          ant.property :key=>'javadoc.type.scope', :value=>'nothing'
          ant.property :key=>'javadoc.var.scope', :value=>'nothing'
          ant.property :key=>'javadoc.lazy', :value=>'true'
          ant.property :key=>'javadoc.missing.param', :value=>'false'
          ant.property :key=>'checkstyle.cache.file', :value=>'target/checkstyle.cache.src'
          ant.property :key=>'checkstyle.header.file', :value=>'buildconf/LICENSE.txt'

          ant.fileset :dir=>"src/test/java", :includes=>'**/*.java'
        end
      end
    end
  end

end

# runs the eclipse task to generate the .classpath and .project
# files, then fixes the output.
task :eclipse do
  puts "Fixing eclipse .classpath"
  text = File.read(".classpath")
  tmp = File.new("tmp", "w")
  tmp.write(text.gsub(/output="target\/resources"/, ""))
  tmp.close()
  FileUtils.copy("tmp", ".classpath")
  File.delete("tmp")
end

#
# extract strings that need to be translated
#
task :extractkeys do
  mkdir_p "po/classes"
  %x{xgettext -ktrc:1c,2 -ktrnc:1c,2,3 -ktr -kmarktr -ktrn:1,2 -o po/keys.pot $(find src/main/java -name "*.java")}
end

#
# merge in changes into existing po files
#
task :mergekeys do
  %x{touch po/de.po}
  %x{msgmerge --backup=none -U po/de.po po/keys.pot}
end

#
# compile resource files
#
task :createresourcebundles do
  puts %x{msgfmt --java2 -d po/classes -r org.fedoraproject.candlepin.i18n.Messages -l de po/de.po}
end


# fix the coverage reports generated by emma.
# we're adding to the existing emma:html task here
# This is AWESOME!
namespace :emma do
   task :html do
      puts "Fixing emma reports"
      fixemmareports("reports/emma/coverage.html")

      dir = "reports/emma/_files"
      Dir.foreach(dir) do |filename|
          fixemmareports("#{dir}/#{filename}") unless filename == "." || filename == ".."
      end
   end
end

# fixes the html produced by emma
def fixemmareports(filetofix)
      text = File.read(filetofix)
      newstr = ''
      text.each_byte do |c|
         if c != 160 then
             newstr.concat(c)
         else
             newstr.concat('&nbsp;')
         end
      end
      tmp = File.new("tmpreport", "w")
      tmp.write(newstr)
      tmp.close()
      FileUtils.copy("tmpreport", filetofix)
      File.delete("tmpreport")
end
