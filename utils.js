var _ = require('./underscore');
_.mixin({
    sentence: function(words) {
        if (!words || words.length === 1) return words;
        if (words.length === 2) return words.join(' ,');
        var beginning = _(words).first(words.length - 1);
        return beginning.join(', ') + " and " + _(words).last();
    }
})