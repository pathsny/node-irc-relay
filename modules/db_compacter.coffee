# monitors the user database and compacts it when the system is idle

COMPACT_TIME_LIMIT = 60000
MAX_REDUNDANT_ROWS = 200

class DbCompacter
  constructor: ({@users}) ->
    @message_listeners = [@listener]
    @private_listeners = [@listener]
    @listener()
    @users.on 'load', @queue_compaction

  listener: =>
    @last_msg_time = new Date().getTime()

  compact: =>
    console.log('trying to compact');
    idle_time = new Date().getTime() - @last_msg_time
    if @users.redundantLength > MAX_REDUNDANT_ROWS and idle_time > COMPACT_TIME_LIMIT
      console.log('compacting');
      @users.once('compacted', @queue_compaction)
      @users.compact()
    else
      @queue_compaction()

  queue_compaction: =>
    setTimeout @compact, COMPACT_TIME_LIMIT


module.exports = DbCompacter