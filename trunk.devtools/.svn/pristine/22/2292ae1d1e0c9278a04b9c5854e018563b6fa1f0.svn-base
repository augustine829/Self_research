class ExecutionError(Exception):
    """
    Instances of this class will be caught and printed to the user as an error
    message.
    """


class UsageError(Exception):
    """
    Instances of this class will be caught and printed to the user as an error
    message preceded by the usage text.
    """


def error(message):
    raise ExecutionError(message)


def usage_error(message):
    raise UsageError(message)


def prompt_user(prompt, default=None):
    # Only import readline in interactive mode since it has the side effect of
    # writing escape codes to the terminal.
    import readline

    if default is not None:
        readline.set_startup_hook(lambda: readline.insert_text(default))
    try:
        while True:
            answer = raw_input(prompt + " ")
            if answer:
                return answer
            else:
                print "Empty value not allowed."
    finally:
        readline.set_startup_hook()
