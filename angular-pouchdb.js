// Generated by CoffeeScript 1.6.3
var dbMethods, useWebWorker, uuid,
  __hasProp = {}.hasOwnProperty;

dbMethods = {
  put: true,
  post: true,
  get: true,
  remove: true,
  bulkDocs: true,
  allDocs: true,
  putAttachment: true,
  getAttachment: true,
  removeAttachment: true,
  query: true,
  info: true,
  compact: true,
  revsDiff: true,
  changes: true
};

uuid = function() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    var r, v;
    r = Math.random() * 16 | 0;
    v = c === 'x' ? r : r & 0x3 | 0x8;
    return v.toString(16);
  });
};

useWebWorker = false;

angular.module('pouchdb', ['ng']).provider('pouchdb', function() {
  return {
    $get: function($q, $rootScope, $timeout) {
      var handleMessage, processMap, qify, worker, workerify;
      processMap = {};
      worker = null;
      qify = function(fn) {
        return function() {
          var args, callback, deferred;
          callback = function(err, res) {
            return $timeout(function() {
              return $rootScope.$apply(function() {
                if (err) {
                  return deferred.reject(err);
                } else {
                  return deferred.resolve(res);
                }
              });
            });
          };
          deferred = $q.defer();
          args = arguments != null ? Array.prototype.slice.call(arguments) : [];
          args.push(callback);
          fn.apply(this, args);
          return deferred.promise;
        };
      };
      workerify = function(dbId, method) {
        return function() {
          var args, deferred, id;
          id = uuid();
          deferred = $q.defer();
          args = arguments != null ? Array.prototype.slice.call(arguments) : [];
          worker.postMessage({
            type: method,
            params: args,
            db: dbId,
            _uuid: id
          });
          processMap[id] = deferred.promise;
          return deferred.promise;
        };
      };
      handleMessage = function() {
        return console.log(arguments);
      };
      return {
        getWorker: function(workerScript, pouchDbScript) {
          if (worker === null && workerScript && pouchDbScript) {
            worker = new Worker(workerScript);
            worker.addEventListener('message', handleMessage, false);
            worker.postMessage({
              type: 'script',
              path: pouchDbScript
            });
            useWebWorker = true;
          }
          return worker;
        },
        closeWorker: function() {
          if (worker !== null) {
            worker.terminate();
            worker = null;
            return useWebWorker = false;
          }
        },
        create: function(name, options) {
          var db, dbId, deferred, id, method, _db, _type;
          if (useWebWorker) {
            id = uuid();
            dbId = uuid();
            _type = null;
            worker = this.getWorker();
            worker.postMessage({
              type: 'type',
              params: [name],
              db: dbId,
              _uuid: id
            });
            deferred = $q.defer();
            processMap[id] = deferred.promise;
            deferred.promise.then(function(result) {
              return _type = result;
            });
            _db = {
              _id: dbId,
              type: function() {
                return _type;
              }
            };
            for (method in dbMethods) {
              if (!__hasProp.call(dbMethods, method)) continue;
              _db[method] = workerify(id, method);
            }
            _db[method] = workerify(id, method);
          } else {
            db = new PouchDB(name, options);
            _db = {
              changes: function(options) {
                var clone;
                clone = angular.copy(options);
                clone.onChange = function(change) {
                  return $timeout(function() {
                    return $rootScope.$apply(function() {
                      return options.onChange(change);
                    });
                  });
                };
                return db.changes(clone);
              },
              type: db.type
            };
            for (method in dbMethods) {
              if (!__hasProp.call(dbMethods, method)) continue;
              _db[method] = qify(db[method]);
            }
          }
          return _db;
        },
        allDbs: qify(PouchDB.allDbs),
        destroy: qify(PouchDB.destroy),
        replicate: PouchDB.replicate
      };
    }
  };
});
