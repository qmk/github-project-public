#!/usr/bin/env node
// USAGE:
// Set environment var GH_TOKEN
// node projects.js organization

var pumpify = require('pumpify')
var requestStream = require('requesturl-stream')
var ts = require('tool-stream')
var request = require('request')
var through = require('through2')
var parseLinkHeader = require('parse-link-header')

var TOKEN = process.env.GH_TOKEN

var APIROOT = 'https://api.github.com/'
var organization = process.argv[2]
var projectURL = APIROOT + 'orgs/' + organization + '/projects'

var requestOptions = {
  json: true,
  headers: {
    'Accept': 'application/vnd.github.inertia-preview+json',
    'Authorization': 'token ' + TOKEN,
    'User-Agent': 'request'
  }
}

var columnsNames = {}
var issuesColumn = {}

var paginateRequest = through.obj(function (obj, enc, next) {
  requestOptions.url = obj
  request(requestOptions, (err, res, json) => {
    if (err) { throw err }
    this.push(json)
    var pages = parseLinkHeader(res.headers.link)
    if (pages && pages.next) {
      paginateRequest.write(pages.next.url)
    }
    next()
  })
})

var pipeline = pumpify.obj(
  requestStream(requestOptions),
  ts.arraySplit(),
  ts.extractProperty('columns_url'),
  requestStream(requestOptions),
  ts.arraySplit(),
  ts.storeToObject(columnsNames, '{{url}}', 'name'),
  ts.extractProperty('cards_url'),
  paginateRequest,
  ts.arraySplit(),
  ts.storeToObject(issuesColumn, '{{content_url}}', 'column_url'),
  ts.extractProperty('content_url'),
  requestStream(requestOptions),
  ts.attachStoredValue(issuesColumn, 'url', 'column_url'),
  ts.attachStoredValue(columnsNames, 'column_url', 'column_name'),
  ts.JSONToBuffer(),
  process.stdout
)

pipeline.write(projectURL)
