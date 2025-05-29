function lsfunc --description 'List functions matching pattern'
    functions -n | string match $argv[1]
end
