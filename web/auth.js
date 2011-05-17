module.exports = function Auth() {
  return function(req, res, next) {
      console.log(req.url);
      next()
    // if (req.remoteUser) return next();
    // if (!authorization) return unauthorized(res, realm);
    // 
    // var parts = authorization.split(' ')
    //   , scheme = parts[0]
    //   , credentials = new Buffer(parts[1], 'base64').toString().split(':');
    // 
    // if ('Basic' != scheme) return badRequest(res);
    // 
    // // async
    // if (callback.length >= 3) {
    //   var pause = utils.pause(req);
    //   callback(credentials[0], credentials[1], function(err, user){
    //     if (err || !user)  return unauthorized(res, realm);
    //     req.remoteUser = user;
    //     next();
    //     pause.resume();
    //   });
    // // sync
    // } else {
    //   if (callback(credentials[0], credentials[1])) {
    //     req.remoteUser = credentials[0];
    //     next();
    //   } else {
    //     unauthorized(res, realm);
    //   }
    // }
  }
};

