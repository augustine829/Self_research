#!/usr/bin/env python2

from string import Template
from os.path import normpath
from os.path import basename
from os.path import dirname
from os import symlink
from os import mkdir
from os import sys
from shutil import copy


def ModuleToProjectName(moduleName):
    return ''.join([basename(moduleName),
                    ' ( ',
                    dirname(moduleName).replace('/', '|'),
                    ' )'])


baseDir = ''.join([sys.argv[2], '/'])
eclipseDir = ''.join([baseDir, '/eclipse/'])
distDir = ''.join([baseDir, '/dist/'])
normModule = normpath(sys.argv[1]).replace(baseDir, '')
moduleProjectDir = ''.join([eclipseDir, normModule.replace('/', '-')])
moduleName = ModuleToProjectName(normModule)
moduleDir = sys.argv[1]
dependencies = sys.argv[4:]

dependentProjects = ''
for dep in dependencies:
    dependentProjects += '<project>'
    dependentProjects += ModuleToProjectName(dep)
    dependentProjects += '</project>\n'

projectTemplateFile = open(
    ''.join(
        [baseDir, 'makesystem/eclipse/eclipse-project.template']))
cprojectTemplateFile = open(
    ''.join(
        [baseDir, 'makesystem/eclipse/eclipse-cproject.template']))

projectTemplate = Template(projectTemplateFile.read())
cprojectTemplate = Template(cprojectTemplateFile.read())

try:
    symlink(moduleDir, moduleProjectDir)
except:
    pass

settingsDir = moduleDir + '/.settings/'
try:
    mkdir(settingsDir)
except:
    pass

copy(''.join([baseDir,
              'makesystem/eclipse/org.eclipse.mylyn.tasks.ui.prefs']),
     settingsDir)

if sys.argv[3] == '3pp':
    copy(''.join([baseDir,
                  'makesystem/eclipse/org.eclipse.cdt.core.prefs']),
         settingsDir)

project_path = ''.join([moduleDir, '/.project'])
cproject_path = ''.join([moduleDir, '/.cproject'])

project = open(project_path, "w")
project.write(
    projectTemplate.safe_substitute(
        DEPENDENT_PROJECTS=dependentProjects,
        PROJECT_NAME=moduleName,
        PROJECT_PATH=moduleDir))
project.close()

cproject = open(cproject_path, "w")
cproject.write(
    cprojectTemplate.safe_substitute(DIST_DIR=distDir,
                                     PROJECT_NAME=moduleName))
cproject.close()
