// DISABLED: because of unknown bug
void f()
{
  int result = (openMode == DATABASE_OPEN_READONLY) ?
    sqlite3_open_v2(fileName.c_str(), &Handle, SQLITE_OPEN_READONLY, NULL) :
    sqlite3_open(fileName.c_str(), &Handle);
}
