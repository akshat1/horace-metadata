_  = require 'lodash'
FS = require 'fs'

class MetadataError extends Error
  constructor: (msg)->
    super msg


class Metadata
  constructor: (id, localPath, @title, @length, @authors, @subjects, @year, @languages, @publishers, @adapter, @adapterSpecificData)->
    throw new MetadataError "No id specified for book id #{id}" unless id
    throw new MetadataError "No localPath specified for book id #{id}" unless localPath
    throw new MetadataError "No title specified for book id #{id}" unless @title
    throw new MetadataError "No authors specified for book id #{id}" unless @authors
    throw new MetadataError "No subjects specified for book id #{id}" unless @subjects
    throw new MetadataError "No year specified for book id #{id}" if typeof @year is 'undefined'
    throw new MetadataError "Invalid year value >#{@year} for book id #{id}<" if isNaN(@year)
    throw new MetadataError "Invalid length value >#{@length} for book id #{id}<" if isNaN(@length)
    throw new MetadataError "No publisher specified for book id #{id}" unless @publishers
    throw new MetadataError "No adapter specified for book id #{id}" unless @adapter

    @year               = parseInt @year
    @_localPath         = localPath
    @_id                = id
    @length             = parseInt @length
    @_search_authors    = _.map @authors, (a)-> a.trim().toLowerCase()
    @_search_subjects   = _.map @subjects, (s)-> s.trim().toLowerCase()
    @_search_publishers = _.map @publishers, (p)-> p.trim().toLowerCase()
    @_search_languages  = _.map @languages, (l)-> l.toLowerCase()
    @_sortTitle         = @title.trim().toLowerCase()


ensureMetadataHasSortableTitle = (metadata)->
  if metadata.hasOwnProperty '_sortTitle'
    false
  else
    metadata._sortTitle = metadata.title.toLowerCase()
    true


ensureMetadataHasAuthors = (metadata)->
  if metadata.hasOwnProperty 'authors' and metadata.hasOwnProperty '_search_authors'
    false
  else
    authors = []
    searchAuthors = []
    pattern = /^author\d*$/
    for key, value of metadata
      if pattern.test(key) and value and value.toLowerCase() isnt 'null'  #That's some dirty dirty metadata we have.
        authors.push value
        searchAuthors.push value.toLowerCase().trim()
    metadata.authors = authors
    metadata._search_authors = searchAuthors
    true


ensureMetadataHasSubjects = (metadata)->
  if metadata.hasOwnProperty 'subjects' and metadata.hasOwnProperty '_search_subjects'
    false
  else
    metadata.subjects = metadata.subject.split ','
    metadata._search_subjects = _.map metadata.subject.toLowerCase().split(','), (s)->s.trim()
    true


ensureMetadataHasId = (metadata)->
  if metadata.hasOwnProperty '_id'
    false
  else
    metadata._id = metadata.barcode
    true


ensureMetadataHasNumberOfPages = (metadata)->
  if metadata.hasOwnProperty 'numberOfPages'
    false
  else
    files = FS.readdirSync metadata._localPath
    testExp = /^page_\d+\.tif$/
    filteredFiles = _.filter files, (f)-> testExp.test f
    metadata.numberOfPages = filteredFiles.length + 1
    true


ensureMetadataHasLocalPath = (metadata, localPath)->
  if metadata.hasOwnProperty '_localPath' or metadata._localPath isnt localPath
    false
  else
    metadata._localPath = localPath
    true


getMassagedMetadataFromFS = (bookPath)->
  mPath = "#{bookPath}/metadata.json"
  str = FS.readFileSync mPath, {encoding: 'utf8'}
  metadata = JSON.parse str

  isDirty =  false
  isDirty = ensureMetadataHasLocalPath(metadata, bookPath) or isDirty
  isDirty = ensureMetadataHasAuthors(metadata) or isDirty
  isDirty = ensureMetadataHasId(metadata) or isDirty
  isDirty = ensureMetadataHasNumberOfPages(metadata) or isDirty
  isDirty = ensureMetadataHasSortableTitle(metadata) or isDirty
  isDirty = ensureMetadataHasSubjects(metadata) or isDirty

  if isDirty
    str = JSON.stringify metadata, null, 2
    FS.writeFileSync mPath, str, {encodiing:'utf8'}

  metadata

isValid = (m)-> m instanceof Metadata


module.exports = Metadata
