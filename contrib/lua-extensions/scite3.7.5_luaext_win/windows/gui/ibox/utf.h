// Unicode / Multibyte conversion Utilities
 
#ifndef UTF_H 
#define UTF_H

#include <string>
#include <winnls.h> // Multibyte/UTF8

#endif

wchar_t* StringFromUTF8(const char *s);
char* UTF8FromString(const std::wstring &s);

struct W2MB
{
	W2MB( const wchar_t *src, int cp )
			: buffer(0)
		{
			int len = ::WideCharToMultiByte( cp, 0, src, -1, 0, 0, 0, 0 );
			if ( len )
			{
				buffer = new char[len];
				len = ::WideCharToMultiByte( cp, 0, src, -1, buffer, len, 0, 0 );
			}
		}
	~W2MB()
		{ delete[] buffer; }
	const char *c_str() const
		{ return buffer; }
private:
	char *buffer;
};

struct MB2W
{
	MB2W( const char *src, int cp )
			: buffer(0)
		{
			int len = ::MultiByteToWideChar( cp, 0, src, -1, 0, 0 );
			if ( len )
			{
				buffer = new wchar_t[len];
				len = ::MultiByteToWideChar( cp, 0, src, -1, buffer, len );
			}
		} 
	~MB2W()
		{ delete[] buffer; }
	const wchar_t *c_str() const
		{ return buffer; }
private:
	wchar_t *buffer;
};
