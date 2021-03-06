#!/usr/bin/env node

const { execFileSync } = require('child_process')

const isRunning = process.argv.includes(__filename)

const DEFAULT_BRANCH = 'master'
const checkAgainst = process.argv[2] || DEFAULT_BRANCH

const exec = (command, args) => {
  if (!isRunning) console.log('> ' + [ command ].concat(args).join(' '))
  const options = {
    cwd: process.cwd(),
    env: process.env,
    stdio: 'pipe',
    encoding: 'utf-8'
  }
  return execFileSync(command, args, options)
}

const execGitCmd = (args) =>
  exec('git', args)
    .trim()
    .toString()
    .split('\n')

const listChangedFiles = () => {
  const mergeBase = execGitCmd(['merge-base', 'HEAD', checkAgainst])
  return new Set([
    ...execGitCmd([ 'diff', '--name-only', '--diff-filter=ACMRTUB', mergeBase ]),
    ...execGitCmd([ 'ls-files', '--others', '--exclude-standard' ])
  ])
}

if (isRunning) console.log([ ...listChangedFiles() ].join('\n'))

module.exports = listChangedFiles
