/*
 * Copyright (C) 2004-2011  See the AUTHORS file for details.
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 2 as published
 * by the Free Software Foundation.
 */

%module znc_core %{
#include <utility>
#include "../Utils.h"
#include "../Socket.h"
#include "../Modules.h"
#include "../Nick.h"
#include "../Chan.h"
#include "../User.h"
#include "../Client.h"
#include "../IRCSock.h"
#include "../Listener.h"
#include "../HTTPSock.h"
#include "../Template.h"
#include "../WebModules.h"
#include "../znc.h"
#include "../Server.h"
#include "../ZNCString.h"
#include "../DCCBounce.h"
#include "../DCCSock.h"
#include "../FileUtils.h"
#include "modpython/module.h"

class CPyRetString {
public:
	CString& s;
	CPyRetString(CString& S) : s(S) {}
	static PyObject* wrap(CString& S) {
		CPyRetString* x = new CPyRetString(S);
		return SWIG_NewInstanceObj(x, SWIG_TypeQuery("CPyRetString*"), SWIG_POINTER_OWN);
	}
};

#define stat struct stat
using std::allocator;
%}

%begin %{
#include "zncconfig.h"
%}

%include <pyabc.i>
%include <typemaps.i>
%include <stl.i>
%include <std_list.i>

namespace std {
	template<class K> class set {
		public:
		set();
		set(const set<K>&);
	};
}

%include "modpython/cstring.i"
%template(_stringlist) std::list<CString>;
/*%typemap(out) std::list<CString> {
	std::list<CString>::const_iterator i;
	unsigned int j;
	int len = $1.size();
	SV **svs = new SV*[len];
	for (i=$1.begin(), j=0; i!=$1.end(); i++, j++) {
		svs[j] = sv_newmortal();
		SwigSvFromString(svs[j], *i);
	}
	AV *myav = av_make(len, svs);
	delete[] svs;
	$result = newRV_noinc((SV*) myav);
	sv_2mortal($result);
	argvi++;
}*/

%typemap(out) CModules::ModDirList %{
	$result = PyList_New($1.size());
	if ($result) {
		for (size_t i = 0; !$1.empty(); $1.pop(), ++i) {
			PyList_SetItem($result, i, Py_BuildValue("ss", $1.front().first.c_str(), $1.front().second.c_str()));
		}
	}
%}

%typemap(in) CString& {
	String* p;
	int res = SWIG_IsOK(SWIG_ConvertPtr($input, (void**)&p, SWIG_TypeQuery("String*"), 0));
	if (SWIG_IsOK(res)) {
		$1 = &p->s;
	} else {
		SWIG_exception_fail(SWIG_ArgError(res), "need znc.String object as argument $argnum $1_name");
	}
}

#define u_short unsigned short
#define u_int unsigned int
#include "../ZNCString.h"
%include "../defines.h"
%include "../Utils.h"
%include "../Csocket.h"
%template(ZNCSocketManager) TSocketManager<CZNCSock>;
%include "../Socket.h"
%include "../DCCBounce.h"
%include "../DCCSock.h"
%include "../FileUtils.h"
%include "../Modules.h"
%include "../Nick.h"
%include "../Chan.h"
%include "../User.h"
%include "../Client.h"
%include "../IRCSock.h"
%include "../Listener.h"
%include "../HTTPSock.h"
%include "../Template.h"
%include "../WebModules.h"
%include "../znc.h"
%include "../Server.h"

%include "modpython/module.h"

/* Really it's CString& inside, but SWIG shouldn't know that :) */
class CPyRetString {
	CPyRetString();
public:
	CString s;
};

%extend CModule {
	MCString_iter BeginNV_() {
		return MCString_iter($self->BeginNV());
	}
	bool ExistsNV(const CString& sName) {
		return $self->EndNV() != $self->FindNV(sName);
	}
}

%extend CModules {
	void push_back(CModule* p) {
		$self->push_back(p);
	}
	bool removeModule(CModule* p) {
		for (CModules::iterator i = $self->begin(); $self->end() != i; ++i) {
			if (*i == p) {
				$self->erase(i);
				return true;
			}
		}
		return false;
	}
}

/* Web */

%template(StrPair) pair<CString, CString>;
%template(VPair) vector<pair<CString, CString> >;
typedef vector<pair<CString, CString> > VPair;
%template(VWebSubPages) vector<TWebSubPage>;

%inline %{
	void VPair_Add2Str_(VPair* self, const CString& a, const CString& b) {
		self->push_back(std::make_pair(a, b));
	}
%}

%extend CTemplate {
	void set(const CString& key, const CString& value) {
		(*$self)[key] = value;
	}
}

%inline %{
	TWebSubPage CreateWebSubPage_(const CString& sName, const CString& sTitle, const VPair& vParams, unsigned int uFlags) {
		return new CWebSubPage(sName, sTitle, vParams, uFlags);
	}
%}

/* vim: set filetype=cpp noexpandtab: */
