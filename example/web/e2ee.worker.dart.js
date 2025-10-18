(function dartProgram(){function copyProperties(a,b){var s=Object.keys(a)
for(var r=0;r<s.length;r++){var q=s[r]
b[q]=a[q]}}function mixinPropertiesHard(a,b){var s=Object.keys(a)
for(var r=0;r<s.length;r++){var q=s[r]
if(!b.hasOwnProperty(q)){b[q]=a[q]}}}function mixinPropertiesEasy(a,b){Object.assign(b,a)}var z=function(){var s=function(){}
s.prototype={p:{}}
var r=new s()
if(!(Object.getPrototypeOf(r)&&Object.getPrototypeOf(r).p===s.prototype.p))return false
try{if(typeof navigator!="undefined"&&typeof navigator.userAgent=="string"&&navigator.userAgent.indexOf("Chrome/")>=0)return true
if(typeof version=="function"&&version.length==0){var q=version()
if(/^\d+\.\d+\.\d+\.\d+$/.test(q))return true}}catch(p){}return false}()
function inherit(a,b){a.prototype.constructor=a
a.prototype["$i"+a.name]=a
if(b!=null){if(z){Object.setPrototypeOf(a.prototype,b.prototype)
return}var s=Object.create(b.prototype)
copyProperties(a.prototype,s)
a.prototype=s}}function inheritMany(a,b){for(var s=0;s<b.length;s++){inherit(b[s],a)}}function mixinEasy(a,b){mixinPropertiesEasy(b.prototype,a.prototype)
a.prototype.constructor=a}function mixinHard(a,b){mixinPropertiesHard(b.prototype,a.prototype)
a.prototype.constructor=a}function lazy(a,b,c,d){var s=a
a[b]=s
a[c]=function(){if(a[b]===s){a[b]=d()}a[c]=function(){return this[b]}
return a[b]}}function lazyFinal(a,b,c,d){var s=a
a[b]=s
a[c]=function(){if(a[b]===s){var r=d()
if(a[b]!==s){A.jr(b)}a[b]=r}var q=a[b]
a[c]=function(){return q}
return q}}function makeConstList(a,b){if(b!=null)A.N(a,b)
a.$flags=7
return a}function convertToFastObject(a){function t(){}t.prototype=a
new t()
return a}function convertAllToFastObject(a){for(var s=0;s<a.length;++s){convertToFastObject(a[s])}}var y=0
function instanceTearOffGetter(a,b){var s=null
return a?function(c){if(s===null)s=A.eM(b)
return new s(c,this)}:function(){if(s===null)s=A.eM(b)
return new s(this,null)}}function staticTearOffGetter(a){var s=null
return function(){if(s===null)s=A.eM(a).prototype
return s}}var x=0
function tearOffParameters(a,b,c,d,e,f,g,h,i,j){if(typeof h=="number"){h+=x}return{co:a,iS:b,iI:c,rC:d,dV:e,cs:f,fs:g,fT:h,aI:i||0,nDA:j}}function installStaticTearOff(a,b,c,d,e,f,g,h){var s=tearOffParameters(a,true,false,c,d,e,f,g,h,false)
var r=staticTearOffGetter(s)
a[b]=r}function installInstanceTearOff(a,b,c,d,e,f,g,h,i,j){c=!!c
var s=tearOffParameters(a,false,c,d,e,f,g,h,i,!!j)
var r=instanceTearOffGetter(c,s)
a[b]=r}function setOrUpdateInterceptorsByTag(a){var s=v.interceptorsByTag
if(!s){v.interceptorsByTag=a
return}copyProperties(a,s)}function setOrUpdateLeafTags(a){var s=v.leafTags
if(!s){v.leafTags=a
return}copyProperties(a,s)}function updateTypes(a){var s=v.types
var r=s.length
s.push.apply(s,a)
return r}function updateHolder(a,b){copyProperties(b,a)
return a}var hunkHelpers=function(){var s=function(a,b,c,d,e){return function(f,g,h,i){return installInstanceTearOff(f,g,a,b,c,d,[h],i,e,false)}},r=function(a,b,c,d){return function(e,f,g,h){return installStaticTearOff(e,f,a,b,c,[g],h,d)}}
return{inherit:inherit,inheritMany:inheritMany,mixin:mixinEasy,mixinHard:mixinHard,installStaticTearOff:installStaticTearOff,installInstanceTearOff:installInstanceTearOff,_instance_0u:s(0,0,null,["$0"],0),_instance_1u:s(0,1,null,["$1"],0),_instance_2u:s(0,2,null,["$2"],0),_instance_0i:s(1,0,null,["$0"],0),_instance_1i:s(1,1,null,["$1"],0),_instance_2i:s(1,2,null,["$2"],0),_static_0:r(0,null,["$0"],0),_static_1:r(1,null,["$1"],0),_static_2:r(2,null,["$2"],0),makeConstList:makeConstList,lazy:lazy,lazyFinal:lazyFinal,updateHolder:updateHolder,convertToFastObject:convertToFastObject,updateTypes:updateTypes,setOrUpdateInterceptorsByTag:setOrUpdateInterceptorsByTag,setOrUpdateLeafTags:setOrUpdateLeafTags}}()
function initializeDeferredHunk(a){x=v.types.length
a(hunkHelpers,v,w,$)}var J={
eQ(a,b,c,d){return{i:a,p:b,e:c,x:d}},
e4(a){var s,r,q,p,o,n=a[v.dispatchPropertyName]
if(n==null)if($.eN==null){A.ji()
n=a[v.dispatchPropertyName]}if(n!=null){s=n.p
if(!1===s)return n.i
if(!0===s)return a
r=Object.getPrototypeOf(a)
if(s===r)return n.i
if(n.e===r)throw A.d(A.fl("Return interceptor for "+A.c(s(a,n))))}q=a.constructor
if(q==null)p=null
else{o=$.dI
if(o==null)o=$.dI=v.getIsolateTag("_$dart_js")
p=q[o]}if(p!=null)return p
p=A.jn(a)
if(p!=null)return p
if(typeof a=="function")return B.N
s=Object.getPrototypeOf(a)
if(s==null)return B.B
if(s===Object.prototype)return B.B
if(typeof q=="function"){o=$.dI
if(o==null)o=$.dI=v.getIsolateTag("_$dart_js")
Object.defineProperty(q,o,{value:B.t,enumerable:false,writable:true,configurable:true})
return B.t}return B.t},
hw(a,b){if(a<0||a>4294967295)throw A.d(A.aa(a,0,4294967295,"length",null))
return J.hx(new Array(a),b)},
hx(a,b){var s=A.N(a,b.h("z<0>"))
s.$flags=1
return s},
aL(a){if(typeof a=="number"){if(Math.floor(a)==a)return J.bl.prototype
return J.cg.prototype}if(typeof a=="string")return J.aT.prototype
if(a==null)return J.bm.prototype
if(typeof a=="boolean")return J.cf.prototype
if(Array.isArray(a))return J.z.prototype
if(typeof a!="object"){if(typeof a=="function")return J.a6.prototype
if(typeof a=="symbol")return J.aV.prototype
if(typeof a=="bigint")return J.aU.prototype
return a}if(a instanceof A.k)return a
return J.e4(a)},
e1(a){if(typeof a=="string")return J.aT.prototype
if(a==null)return a
if(Array.isArray(a))return J.z.prototype
if(typeof a!="object"){if(typeof a=="function")return J.a6.prototype
if(typeof a=="symbol")return J.aV.prototype
if(typeof a=="bigint")return J.aU.prototype
return a}if(a instanceof A.k)return a
return J.e4(a)},
e2(a){if(a==null)return a
if(Array.isArray(a))return J.z.prototype
if(typeof a!="object"){if(typeof a=="function")return J.a6.prototype
if(typeof a=="symbol")return J.aV.prototype
if(typeof a=="bigint")return J.aU.prototype
return a}if(a instanceof A.k)return a
return J.e4(a)},
e3(a){if(a==null)return a
if(typeof a!="object"){if(typeof a=="function")return J.a6.prototype
if(typeof a=="symbol")return J.aV.prototype
if(typeof a=="bigint")return J.aU.prototype
return a}if(a instanceof A.k)return a
return J.e4(a)},
eT(a,b){if(a==null)return b==null
if(typeof a!="object")return b!=null&&a===b
return J.aL(a).F(a,b)},
eU(a,b){if(typeof b==="number")if(Array.isArray(a)||typeof a=="string"||A.jl(a,a[v.dispatchPropertyName]))if(b>>>0===b&&b<a.length)return a[b]
return J.e1(a).j(a,b)},
eV(a,b,c){return J.e3(a).bt(a,b,c)},
be(a,b){return J.e2(a).u(a,b)},
et(a){return J.e3(a).aV(a)},
eW(a,b,c){return J.e3(a).a4(a,b,c)},
hi(a,b){return J.e2(a).T(a,b)},
eu(a){return J.e3(a).gH(a)},
cR(a){return J.aL(a).gt(a)},
ev(a){return J.e2(a).gA(a)},
aQ(a){return J.e1(a).gm(a)},
ew(a){return J.aL(a).gq(a)},
hj(a,b,c){return J.e2(a).V(a,b,c)},
T(a){return J.aL(a).k(a)},
cd:function cd(){},
cf:function cf(){},
bm:function bm(){},
bn:function bn(){},
al:function al(){},
ct:function ct(){},
bE:function bE(){},
a6:function a6(){},
aU:function aU(){},
aV:function aV(){},
z:function z(a){this.$ti=a},
ce:function ce(){},
d6:function d6(a){this.$ti=a},
bf:function bf(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
ch:function ch(){},
bl:function bl(){},
cg:function cg(){},
aT:function aT(){}},A={eA:function eA(){},
hy(a){return new A.bo("Field '"+a+"' has not been initialized.")},
fj(a,b){a=a+b&536870911
a=a+((a&524287)<<10)&536870911
return a^a>>>6},
hR(a){a=a+((a&67108863)<<3)&536870911
a^=a>>>11
return a+((a&16383)<<15)&536870911},
dY(a,b,c){return a},
eO(a){var s,r
for(s=$.S.length,r=0;r<s;++r)if(a===$.S[r])return!0
return!1},
hA(a,b,c,d){if(t.d.b(a))return new A.bi(a,b,c.h("@<0>").l(d).h("bi<1,2>"))
return new A.a8(a,b,c.h("@<0>").l(d).h("a8<1,2>"))},
b2:function b2(a){this.a=0
this.b=a},
bo:function bo(a){this.a=a},
de:function de(){},
l:function l(){},
a7:function a7(){},
aA:function aA(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
a8:function a8(a,b,c){this.a=a
this.b=b
this.$ti=c},
bi:function bi(a,b,c){this.a=a
this.b=b
this.$ti=c},
bt:function bt(a,b,c){var _=this
_.a=null
_.b=a
_.c=b
_.$ti=c},
a9:function a9(a,b,c){this.a=a
this.b=b
this.$ti=c},
aE:function aE(a,b,c){this.a=a
this.b=b
this.$ti=c},
bH:function bH(a,b,c){this.a=a
this.b=b
this.$ti=c},
L:function L(){},
h3(a){var s=v.mangledGlobalNames[a]
if(s!=null)return s
return"minified:"+a},
jl(a,b){var s
if(b!=null){s=b.x
if(s!=null)return s}return t.w.b(a)},
c(a){var s
if(typeof a=="string")return a
if(typeof a=="number"){if(a!==0)return""+a}else if(!0===a)return"true"
else if(!1===a)return"false"
else if(a==null)return"null"
s=J.T(a)
return s},
bB(a){var s,r=$.fb
if(r==null)r=$.fb=Symbol("identityHashCode")
s=a[r]
if(s==null){s=Math.random()*0x3fffffff|0
a[r]=s}return s},
cu(a){var s,r,q,p
if(a instanceof A.k)return A.R(A.bb(a),null)
s=J.aL(a)
if(s===B.M||s===B.O||t.cr.b(a)){r=B.v(a)
if(r!=="Object"&&r!=="")return r
q=a.constructor
if(typeof q=="function"){p=q.name
if(typeof p=="string"&&p!=="Object"&&p!=="")return p}}return A.R(A.bb(a),null)},
hL(a){var s,r,q
if(typeof a=="number"||A.dV(a))return J.T(a)
if(typeof a=="string")return JSON.stringify(a)
if(a instanceof A.aj)return a.k(0)
s=$.hh()
for(r=0;r<1;++r){q=s[r].bW(a)
if(q!=null)return q}return"Instance of '"+A.cu(a)+"'"},
hM(a,b,c){var s,r,q,p
if(c<=500&&b===0&&c===a.length)return String.fromCharCode.apply(null,a)
for(s=b,r="";s<c;s=q){q=s+500
p=q<c?q:c
r+=String.fromCharCode.apply(null,a.subarray(s,p))}return r},
Q(a){if(a.date===void 0)a.date=new Date(a.a)
return a.date},
hK(a){return a.c?A.Q(a).getUTCFullYear()+0:A.Q(a).getFullYear()+0},
hI(a){return a.c?A.Q(a).getUTCMonth()+1:A.Q(a).getMonth()+1},
hE(a){return a.c?A.Q(a).getUTCDate()+0:A.Q(a).getDate()+0},
hF(a){return a.c?A.Q(a).getUTCHours()+0:A.Q(a).getHours()+0},
hH(a){return a.c?A.Q(a).getUTCMinutes()+0:A.Q(a).getMinutes()+0},
hJ(a){return a.c?A.Q(a).getUTCSeconds()+0:A.Q(a).getSeconds()+0},
hG(a){return a.c?A.Q(a).getUTCMilliseconds()+0:A.Q(a).getMilliseconds()+0},
hD(a){var s=a.$thrownJsError
if(s==null)return null
return A.aM(s)},
fc(a,b){var s
if(a.$thrownJsError==null){s=new Error()
A.B(a,s)
a.$thrownJsError=s
s.stack=b.k(0)}},
jg(a){throw A.d(A.j2(a))},
e(a,b){if(a==null)J.aQ(a)
throw A.d(A.cO(a,b))},
cO(a,b){var s,r="index"
if(!A.fJ(b))return new A.Z(!0,b,r,null)
s=A.p(J.aQ(a))
if(b<0||b>=s)return A.f2(b,s,a,r)
return A.hN(b,r)},
ja(a,b,c){if(a<0||a>c)return A.aa(a,0,c,"start",null)
if(b!=null)if(b<a||b>c)return A.aa(b,a,c,"end",null)
return new A.Z(!0,b,"end",null)},
j2(a){return new A.Z(!0,a,null,null)},
d(a){return A.B(a,new Error())},
B(a,b){var s
if(a==null)a=new A.ab()
b.dartException=a
s=A.js
if("defineProperty" in Object){Object.defineProperty(b,"message",{get:s})
b.name=""}else b.toString=s
return b},
js(){return J.T(this.dartException)},
W(a,b){throw A.B(a,b==null?new Error():b)},
X(a,b,c){var s
if(b==null)b=0
if(c==null)c=0
s=Error()
A.W(A.is(a,b,c),s)},
is(a,b,c){var s,r,q,p,o,n,m,l,k
if(typeof b=="string")s=b
else{r="[]=;add;removeWhere;retainWhere;removeRange;setRange;setInt8;setInt16;setInt32;setUint8;setUint16;setUint32;setFloat32;setFloat64".split(";")
q=r.length
p=b
if(p>q){c=p/q|0
p%=q}s=r[p]}o=typeof c=="string"?c:"modify;remove from;add to".split(";")[c]
n=t.cK.b(a)?"list":"ByteData"
m=a.$flags|0
l="a "
if((m&4)!==0)k="constant "
else if((m&2)!==0){k="unmodifiable "
l="an "}else k=(m&1)!==0?"fixed-length ":""
return new A.bF("'"+s+"': Cannot "+o+" "+l+k+n)},
bd(a){throw A.d(A.bh(a))},
ac(a){var s,r,q,p,o,n
a=A.jq(a.replace(String({}),"$receiver$"))
s=a.match(/\\\$[a-zA-Z]+\\\$/g)
if(s==null)s=A.N([],t.s)
r=s.indexOf("\\$arguments\\$")
q=s.indexOf("\\$argumentsExpr\\$")
p=s.indexOf("\\$expr\\$")
o=s.indexOf("\\$method\\$")
n=s.indexOf("\\$receiver\\$")
return new A.dj(a.replace(new RegExp("\\\\\\$arguments\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$argumentsExpr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$expr\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$method\\\\\\$","g"),"((?:x|[^x])*)").replace(new RegExp("\\\\\\$receiver\\\\\\$","g"),"((?:x|[^x])*)"),r,q,p,o,n)},
dk(a){return function($expr$){var $argumentsExpr$="$arguments$"
try{$expr$.$method$($argumentsExpr$)}catch(s){return s.message}}(a)},
fk(a){return function($expr$){try{$expr$.$method$}catch(s){return s.message}}(a)},
eB(a,b){var s=b==null,r=s?null:b.method
return new A.ci(a,r,s?null:b.receiver)},
M(a){var s
if(a==null)return new A.dd(a)
if(a instanceof A.bk){s=a.a
return A.at(a,s==null?A.J(s):s)}if(typeof a!=="object")return a
if("dartException" in a)return A.at(a,a.dartException)
return A.j1(a)},
at(a,b){if(t.C.b(b))if(b.$thrownJsError==null)b.$thrownJsError=a
return b},
j1(a){var s,r,q,p,o,n,m,l,k,j,i,h,g
if(!("message" in a))return a
s=a.message
if("number" in a&&typeof a.number=="number"){r=a.number
q=r&65535
if((B.i.a3(r,16)&8191)===10)switch(q){case 438:return A.at(a,A.eB(A.c(s)+" (Error "+q+")",null))
case 445:case 5007:A.c(s)
return A.at(a,new A.bA())}}if(a instanceof TypeError){p=$.h4()
o=$.h5()
n=$.h6()
m=$.h7()
l=$.ha()
k=$.hb()
j=$.h9()
$.h8()
i=$.hd()
h=$.hc()
g=p.C(s)
if(g!=null)return A.at(a,A.eB(A.h(s),g))
else{g=o.C(s)
if(g!=null){g.method="call"
return A.at(a,A.eB(A.h(s),g))}else if(n.C(s)!=null||m.C(s)!=null||l.C(s)!=null||k.C(s)!=null||j.C(s)!=null||m.C(s)!=null||i.C(s)!=null||h.C(s)!=null){A.h(s)
return A.at(a,new A.bA())}}return A.at(a,new A.cB(typeof s=="string"?s:""))}if(a instanceof RangeError){if(typeof s=="string"&&s.indexOf("call stack")!==-1)return new A.bD()
s=function(b){try{return String(b)}catch(f){}return null}(a)
return A.at(a,new A.Z(!1,null,null,typeof s=="string"?s.replace(/^RangeError:\s*/,""):s))}if(typeof InternalError=="function"&&a instanceof InternalError)if(typeof s=="string"&&s==="too much recursion")return new A.bD()
return a},
aM(a){var s
if(a instanceof A.bk)return a.b
if(a==null)return new A.bU(a)
s=a.$cachedTrace
if(s!=null)return s
s=new A.bU(a)
if(typeof a==="object")a.$cachedTrace=s
return s},
em(a){if(a==null)return J.cR(a)
if(typeof a=="object")return A.bB(a)
return J.cR(a)},
jb(a,b){var s,r,q,p=a.length
for(s=0;s<p;s=q){r=s+1
q=r+1
b.v(0,a[s],a[r])}return b},
iC(a,b,c,d,e,f){t.Z.a(a)
switch(A.p(b)){case 0:return a.$0()
case 1:return a.$1(c)
case 2:return a.$2(c,d)
case 3:return a.$3(c,d,e)
case 4:return a.$4(c,d,e,f)}throw A.d(A.a3("Unsupported number of arguments for wrapped closure"))},
c2(a,b){var s=a.$identity
if(!!s)return s
s=A.j8(a,b)
a.$identity=s
return s},
j8(a,b){var s
switch(b){case 0:s=a.$0
break
case 1:s=a.$1
break
case 2:s=a.$2
break
case 3:s=a.$3
break
case 4:s=a.$4
break
default:s=null}if(s!=null)return s.bind(a)
return function(c,d,e){return function(f,g,h,i){return e(c,d,f,g,h,i)}}(a,b,A.iC)},
hr(a2){var s,r,q,p,o,n,m,l,k,j,i=a2.co,h=a2.iS,g=a2.iI,f=a2.nDA,e=a2.aI,d=a2.fs,c=a2.cs,b=d[0],a=c[0],a0=i[b],a1=a2.fT
a1.toString
s=h?Object.create(new A.cw().constructor.prototype):Object.create(new A.aR(null,null).constructor.prototype)
s.$initialize=s.constructor
r=h?function static_tear_off(){this.$initialize()}:function tear_off(a3,a4){this.$initialize(a3,a4)}
s.constructor=r
r.prototype=s
s.$_name=b
s.$_target=a0
q=!h
if(q)p=A.f0(b,a0,g,f)
else{s.$static_name=b
p=a0}s.$S=A.hn(a1,h,g)
s[a]=p
for(o=p,n=1;n<d.length;++n){m=d[n]
if(typeof m=="string"){l=i[m]
k=m
m=l}else k=""
j=c[n]
if(j!=null){if(q)m=A.f0(k,m,g,f)
s[j]=m}if(n===e)o=m}s.$C=o
s.$R=a2.rC
s.$D=a2.dV
return r},
hn(a,b,c){if(typeof a=="number")return a
if(typeof a=="string"){if(b)throw A.d("Cannot compute signature for static tearoff.")
return function(d,e){return function(){return e(this,d)}}(a,A.hk)}throw A.d("Error in functionType of tearoff")},
ho(a,b,c,d){var s=A.f_
switch(b?-1:a){case 0:return function(e,f){return function(){return f(this)[e]()}}(c,s)
case 1:return function(e,f){return function(g){return f(this)[e](g)}}(c,s)
case 2:return function(e,f){return function(g,h){return f(this)[e](g,h)}}(c,s)
case 3:return function(e,f){return function(g,h,i){return f(this)[e](g,h,i)}}(c,s)
case 4:return function(e,f){return function(g,h,i,j){return f(this)[e](g,h,i,j)}}(c,s)
case 5:return function(e,f){return function(g,h,i,j,k){return f(this)[e](g,h,i,j,k)}}(c,s)
default:return function(e,f){return function(){return e.apply(f(this),arguments)}}(d,s)}},
f0(a,b,c,d){if(c)return A.hq(a,b,d)
return A.ho(b.length,d,a,b)},
hp(a,b,c,d){var s=A.f_,r=A.hl
switch(b?-1:a){case 0:throw A.d(new A.cv("Intercepted function with no arguments."))
case 1:return function(e,f,g){return function(){return f(this)[e](g(this))}}(c,r,s)
case 2:return function(e,f,g){return function(h){return f(this)[e](g(this),h)}}(c,r,s)
case 3:return function(e,f,g){return function(h,i){return f(this)[e](g(this),h,i)}}(c,r,s)
case 4:return function(e,f,g){return function(h,i,j){return f(this)[e](g(this),h,i,j)}}(c,r,s)
case 5:return function(e,f,g){return function(h,i,j,k){return f(this)[e](g(this),h,i,j,k)}}(c,r,s)
case 6:return function(e,f,g){return function(h,i,j,k,l){return f(this)[e](g(this),h,i,j,k,l)}}(c,r,s)
default:return function(e,f,g){return function(){var q=[g(this)]
Array.prototype.push.apply(q,arguments)
return e.apply(f(this),q)}}(d,r,s)}},
hq(a,b,c){var s,r
if($.eY==null)$.eY=A.eX("interceptor")
if($.eZ==null)$.eZ=A.eX("receiver")
s=b.length
r=A.hp(s,c,a,b)
return r},
eM(a){return A.hr(a)},
hk(a,b){return A.dQ(v.typeUniverse,A.bb(a.a),b)},
f_(a){return a.a},
hl(a){return a.b},
eX(a){var s,r,q,p=new A.aR("receiver","interceptor"),o=Object.getOwnPropertyNames(p)
o.$flags=1
s=o
for(o=s.length,r=0;r<o;++r){q=s[r]
if(p[q]===a)return q}throw A.d(A.ai("Field name "+a+" not found.",null))},
jd(a){return v.getIsolateTag(a)},
jR(a,b,c){Object.defineProperty(a,b,{value:c,enumerable:false,writable:true,configurable:true})},
jn(a){var s,r,q,p,o,n=A.h($.fZ.$1(a)),m=$.e_[n]
if(m!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}s=$.e9[n]
if(s!=null)return s
r=v.interceptorsByTag[n]
if(r==null){q=A.dS($.fT.$2(a,n))
if(q!=null){m=$.e_[q]
if(m!=null){Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}s=$.e9[q]
if(s!=null)return s
r=v.interceptorsByTag[q]
n=q}}if(r==null)return null
s=r.prototype
p=n[0]
if(p==="!"){m=A.el(s)
$.e_[n]=m
Object.defineProperty(a,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
return m.i}if(p==="~"){$.e9[n]=s
return s}if(p==="-"){o=A.el(s)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:o,enumerable:false,writable:true,configurable:true})
return o.i}if(p==="+")return A.h0(a,s)
if(p==="*")throw A.d(A.fl(n))
if(v.leafTags[n]===true){o=A.el(s)
Object.defineProperty(Object.getPrototypeOf(a),v.dispatchPropertyName,{value:o,enumerable:false,writable:true,configurable:true})
return o.i}else return A.h0(a,s)},
h0(a,b){var s=Object.getPrototypeOf(a)
Object.defineProperty(s,v.dispatchPropertyName,{value:J.eQ(b,s,null,null),enumerable:false,writable:true,configurable:true})
return b},
el(a){return J.eQ(a,!1,null,!!a.$iP)},
jo(a,b,c){var s=b.prototype
if(v.leafTags[a]===true)return A.el(s)
else return J.eQ(s,c,null,null)},
ji(){if(!0===$.eN)return
$.eN=!0
A.jj()},
jj(){var s,r,q,p,o,n,m,l
$.e_=Object.create(null)
$.e9=Object.create(null)
A.jh()
s=v.interceptorsByTag
r=Object.getOwnPropertyNames(s)
if(typeof window!="undefined"){window
q=function(){}
for(p=0;p<r.length;++p){o=r[p]
n=$.h1.$1(o)
if(n!=null){m=A.jo(o,s[o],n)
if(m!=null){Object.defineProperty(n,v.dispatchPropertyName,{value:m,enumerable:false,writable:true,configurable:true})
q.prototype=n}}}}for(p=0;p<r.length;++p){o=r[p]
if(/^[A-Za-z_]/.test(o)){l=s[o]
s["!"+o]=l
s["~"+o]=l
s["-"+o]=l
s["+"+o]=l
s["*"+o]=l}}},
jh(){var s,r,q,p,o,n,m=B.E()
m=A.b9(B.F,A.b9(B.G,A.b9(B.w,A.b9(B.w,A.b9(B.H,A.b9(B.I,A.b9(B.J(B.v),m)))))))
if(typeof dartNativeDispatchHooksTransformer!="undefined"){s=dartNativeDispatchHooksTransformer
if(typeof s=="function")s=[s]
if(Array.isArray(s))for(r=0;r<s.length;++r){q=s[r]
if(typeof q=="function")m=q(m)||m}}p=m.getTag
o=m.getUnknownTag
n=m.prototypeForTag
$.fZ=new A.e6(p)
$.fT=new A.e7(o)
$.h1=new A.e8(n)},
b9(a,b){return a(b)||b},
j9(a,b){var s=b.length,r=v.rttc[""+s+";"+a]
if(r==null)return null
if(s===0)return r
if(s===r.length)return r.apply(null,b)
return r(b)},
jq(a){if(/[[\]{}()*+?.\\^$|]/.test(a))return a.replace(/[[\]{}()*+?.\\^$|]/g,"\\$&")
return a},
bC:function bC(){},
dj:function dj(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
bA:function bA(){},
ci:function ci(a,b,c){this.a=a
this.b=b
this.c=c},
cB:function cB(a){this.a=a},
dd:function dd(a){this.a=a},
bk:function bk(a,b){this.a=a
this.b=b},
bU:function bU(a){this.a=a
this.b=null},
aj:function aj(){},
c6:function c6(){},
c7:function c7(){},
cy:function cy(){},
cw:function cw(){},
aR:function aR(a,b){this.a=a
this.b=b},
cv:function cv(a){this.a=a},
az:function az(a){var _=this
_.a=0
_.f=_.e=_.d=_.c=_.b=null
_.r=0
_.$ti=a},
d8:function d8(a,b){var _=this
_.a=a
_.b=b
_.d=_.c=null},
bq:function bq(a,b){this.a=a
this.$ti=b},
bp:function bp(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.$ti=d},
e6:function e6(a){this.a=a},
e7:function e7(a){this.a=a},
e8:function e8(a){this.a=a},
ar(a){return a},
hB(a){return new DataView(new ArrayBuffer(a))},
f8(a){return new Uint8Array(a)},
I(a,b,c){return c==null?new Uint8Array(a,b):new Uint8Array(a,b,c)},
aJ(a,b,c){if(a>>>0!==a||a>=c)throw A.d(A.cO(b,a))},
ir(a,b,c){var s
if(!(a>>>0!==a))if(b==null)s=a>c
else s=b>>>0!==b||a>b||b>c
else s=!0
if(s)throw A.d(A.ja(a,b,c))
if(b==null)return c
return b},
an:function an(){},
aY:function aY(){},
bx:function bx(){},
cL:function cL(a){this.a=a},
bu:function bu(){},
C:function C(){},
bv:function bv(){},
bw:function bw(){},
ck:function ck(){},
cl:function cl(){},
cm:function cm(){},
cn:function cn(){},
co:function co(){},
cp:function cp(){},
cq:function cq(){},
by:function by(){},
bz:function bz(){},
bQ:function bQ(){},
bR:function bR(){},
bS:function bS(){},
bT:function bT(){},
eC(a,b){var s=b.c
return s==null?b.c=A.bY(a,"a_",[b.x]):s},
ff(a){var s=a.w
if(s===6||s===7)return A.ff(a.x)
return s===11||s===12},
hO(a){return a.as},
ba(a){return A.dP(v.typeUniverse,a,!1)},
aK(a1,a2,a3,a4){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0=a2.w
switch(a0){case 5:case 1:case 2:case 3:case 4:return a2
case 6:s=a2.x
r=A.aK(a1,s,a3,a4)
if(r===s)return a2
return A.fy(a1,r,!0)
case 7:s=a2.x
r=A.aK(a1,s,a3,a4)
if(r===s)return a2
return A.fx(a1,r,!0)
case 8:q=a2.y
p=A.b8(a1,q,a3,a4)
if(p===q)return a2
return A.bY(a1,a2.x,p)
case 9:o=a2.x
n=A.aK(a1,o,a3,a4)
m=a2.y
l=A.b8(a1,m,a3,a4)
if(n===o&&l===m)return a2
return A.eG(a1,n,l)
case 10:k=a2.x
j=a2.y
i=A.b8(a1,j,a3,a4)
if(i===j)return a2
return A.fz(a1,k,i)
case 11:h=a2.x
g=A.aK(a1,h,a3,a4)
f=a2.y
e=A.iZ(a1,f,a3,a4)
if(g===h&&e===f)return a2
return A.fw(a1,g,e)
case 12:d=a2.y
a4+=d.length
c=A.b8(a1,d,a3,a4)
o=a2.x
n=A.aK(a1,o,a3,a4)
if(c===d&&n===o)return a2
return A.eH(a1,n,c,!0)
case 13:b=a2.x
if(b<a4)return a2
a=a3[b-a4]
if(a==null)return a2
return a
default:throw A.d(A.c4("Attempted to substitute unexpected RTI kind "+a0))}},
b8(a,b,c,d){var s,r,q,p,o=b.length,n=A.dR(o)
for(s=!1,r=0;r<o;++r){q=b[r]
p=A.aK(a,q,c,d)
if(p!==q)s=!0
n[r]=p}return s?n:b},
j_(a,b,c,d){var s,r,q,p,o,n,m=b.length,l=A.dR(m)
for(s=!1,r=0;r<m;r+=3){q=b[r]
p=b[r+1]
o=b[r+2]
n=A.aK(a,o,c,d)
if(n!==o)s=!0
l.splice(r,3,q,p,n)}return s?l:b},
iZ(a,b,c,d){var s,r=b.a,q=A.b8(a,r,c,d),p=b.b,o=A.b8(a,p,c,d),n=b.c,m=A.j_(a,n,c,d)
if(q===r&&o===p&&m===n)return b
s=new A.cG()
s.a=q
s.b=o
s.c=m
return s},
N(a,b){a[v.arrayRti]=b
return a},
fV(a){var s=a.$S
if(s!=null){if(typeof s=="number")return A.jf(s)
return a.$S()}return null},
jk(a,b){var s
if(A.ff(b))if(a instanceof A.aj){s=A.fV(a)
if(s!=null)return s}return A.bb(a)},
bb(a){if(a instanceof A.k)return A.K(a)
if(Array.isArray(a))return A.ae(a)
return A.eJ(J.aL(a))},
ae(a){var s=a[v.arrayRti],r=t.r
if(s==null)return r
if(s.constructor!==r.constructor)return r
return s},
K(a){var s=a.$ti
return s!=null?s:A.eJ(a)},
eJ(a){var s=a.constructor,r=s.$ccache
if(r!=null)return r
return A.iz(a,s)},
iz(a,b){var s=a instanceof A.aj?Object.getPrototypeOf(Object.getPrototypeOf(a)).constructor:b,r=A.ig(v.typeUniverse,s.name)
b.$ccache=r
return r},
jf(a){var s,r=v.types,q=r[a]
if(typeof q=="string"){s=A.dP(v.typeUniverse,q,!1)
r[a]=s
return s}return q},
je(a){return A.as(A.K(a))},
iY(a){var s=a instanceof A.aj?A.fV(a):null
if(s!=null)return s
if(t.a4.b(a))return J.ew(a).a
if(Array.isArray(a))return A.ae(a)
return A.bb(a)},
as(a){var s=a.r
return s==null?a.r=new A.dO(a):s},
Y(a){return A.as(A.dP(v.typeUniverse,a,!1))},
iy(a){var s=this
s.b=A.iW(s)
return s.b(a)},
iW(a){var s,r,q,p,o
if(a===t.K)return A.iI
if(A.aN(a))return A.iM
s=a.w
if(s===6)return A.iw
if(s===1)return A.fL
if(s===7)return A.iD
r=A.iV(a)
if(r!=null)return r
if(s===8){q=a.x
if(a.y.every(A.aN)){a.f="$i"+q
if(q==="r")return A.iG
if(a===t.m)return A.iF
return A.iL}}else if(s===10){p=A.j9(a.x,a.y)
o=p==null?A.fL:p
return o==null?A.J(o):o}return A.iu},
iV(a){if(a.w===8){if(a===t.S)return A.fJ
if(a===t.i||a===t.o)return A.iH
if(a===t.N)return A.iK
if(a===t.y)return A.dV}return null},
ix(a){var s=this,r=A.it
if(A.aN(s))r=A.im
else if(s===t.K)r=A.J
else if(A.bc(s)){r=A.iv
if(s===t.a3)r=A.eI
else if(s===t.T)r=A.dS
else if(s===t.cG)r=A.ii
else if(s===t.ae)r=A.fD
else if(s===t.dd)r=A.ij
else if(s===t.b1)r=A.ik}else if(s===t.S)r=A.p
else if(s===t.N)r=A.h
else if(s===t.y)r=A.cM
else if(s===t.o)r=A.il
else if(s===t.i)r=A.fC
else if(s===t.m)r=A.b
s.a=r
return s.a(a)},
iu(a){var s=this
if(a==null)return A.bc(s)
return A.jm(v.typeUniverse,A.jk(a,s),s)},
iw(a){if(a==null)return!0
return this.x.b(a)},
iL(a){var s,r=this
if(a==null)return A.bc(r)
s=r.f
if(a instanceof A.k)return!!a[s]
return!!J.aL(a)[s]},
iG(a){var s,r=this
if(a==null)return A.bc(r)
if(typeof a!="object")return!1
if(Array.isArray(a))return!0
s=r.f
if(a instanceof A.k)return!!a[s]
return!!J.aL(a)[s]},
iF(a){var s=this
if(a==null)return!1
if(typeof a=="object"){if(a instanceof A.k)return!!a[s.f]
return!0}if(typeof a=="function")return!0
return!1},
fK(a){if(typeof a=="object"){if(a instanceof A.k)return t.m.b(a)
return!0}if(typeof a=="function")return!0
return!1},
it(a){var s=this
if(a==null){if(A.bc(s))return a}else if(s.b(a))return a
throw A.B(A.fE(a,s),new Error())},
iv(a){var s=this
if(a==null||s.b(a))return a
throw A.B(A.fE(a,s),new Error())},
fE(a,b){return new A.bW("TypeError: "+A.fo(a,A.R(b,null)))},
fo(a,b){return A.cW(a)+": type '"+A.R(A.iY(a),null)+"' is not a subtype of type '"+b+"'"},
U(a,b){return new A.bW("TypeError: "+A.fo(a,b))},
iD(a){var s=this
return s.x.b(a)||A.eC(v.typeUniverse,s).b(a)},
iI(a){return a!=null},
J(a){if(a!=null)return a
throw A.B(A.U(a,"Object"),new Error())},
iM(a){return!0},
im(a){return a},
fL(a){return!1},
dV(a){return!0===a||!1===a},
cM(a){if(!0===a)return!0
if(!1===a)return!1
throw A.B(A.U(a,"bool"),new Error())},
ii(a){if(!0===a)return!0
if(!1===a)return!1
if(a==null)return a
throw A.B(A.U(a,"bool?"),new Error())},
fC(a){if(typeof a=="number")return a
throw A.B(A.U(a,"double"),new Error())},
ij(a){if(typeof a=="number")return a
if(a==null)return a
throw A.B(A.U(a,"double?"),new Error())},
fJ(a){return typeof a=="number"&&Math.floor(a)===a},
p(a){if(typeof a=="number"&&Math.floor(a)===a)return a
throw A.B(A.U(a,"int"),new Error())},
eI(a){if(typeof a=="number"&&Math.floor(a)===a)return a
if(a==null)return a
throw A.B(A.U(a,"int?"),new Error())},
iH(a){return typeof a=="number"},
il(a){if(typeof a=="number")return a
throw A.B(A.U(a,"num"),new Error())},
fD(a){if(typeof a=="number")return a
if(a==null)return a
throw A.B(A.U(a,"num?"),new Error())},
iK(a){return typeof a=="string"},
h(a){if(typeof a=="string")return a
throw A.B(A.U(a,"String"),new Error())},
dS(a){if(typeof a=="string")return a
if(a==null)return a
throw A.B(A.U(a,"String?"),new Error())},
b(a){if(A.fK(a))return a
throw A.B(A.U(a,"JSObject"),new Error())},
ik(a){if(a==null)return a
if(A.fK(a))return a
throw A.B(A.U(a,"JSObject?"),new Error())},
fQ(a,b){var s,r,q
for(s="",r="",q=0;q<a.length;++q,r=", ")s+=r+A.R(a[q],b)
return s},
iR(a,b){var s,r,q,p,o,n,m=a.x,l=a.y
if(""===m)return"("+A.fQ(l,b)+")"
s=l.length
r=m.split(",")
q=r.length-s
for(p="(",o="",n=0;n<s;++n,o=", "){p+=o
if(q===0)p+="{"
p+=A.R(l[n],b)
if(q>=0)p+=" "+r[q];++q}return p+"})"},
fF(a3,a4,a5){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1=", ",a2=null
if(a5!=null){s=a5.length
if(a4==null)a4=A.N([],t.s)
else a2=a4.length
r=a4.length
for(q=s;q>0;--q)B.d.u(a4,"T"+(r+q))
for(p=t.X,o="<",n="",q=0;q<s;++q,n=a1){m=a4.length
l=m-1-q
if(!(l>=0))return A.e(a4,l)
o=o+n+a4[l]
k=a5[q]
j=k.w
if(!(j===2||j===3||j===4||j===5||k===p))o+=" extends "+A.R(k,a4)}o+=">"}else o=""
p=a3.x
i=a3.y
h=i.a
g=h.length
f=i.b
e=f.length
d=i.c
c=d.length
b=A.R(p,a4)
for(a="",a0="",q=0;q<g;++q,a0=a1)a+=a0+A.R(h[q],a4)
if(e>0){a+=a0+"["
for(a0="",q=0;q<e;++q,a0=a1)a+=a0+A.R(f[q],a4)
a+="]"}if(c>0){a+=a0+"{"
for(a0="",q=0;q<c;q+=3,a0=a1){a+=a0
if(d[q+1])a+="required "
a+=A.R(d[q+2],a4)+" "+d[q]}a+="}"}if(a2!=null){a4.toString
a4.length=a2}return o+"("+a+") => "+b},
R(a,b){var s,r,q,p,o,n,m,l=a.w
if(l===5)return"erased"
if(l===2)return"dynamic"
if(l===3)return"void"
if(l===1)return"Never"
if(l===4)return"any"
if(l===6){s=a.x
r=A.R(s,b)
q=s.w
return(q===11||q===12?"("+r+")":r)+"?"}if(l===7)return"FutureOr<"+A.R(a.x,b)+">"
if(l===8){p=A.j0(a.x)
o=a.y
return o.length>0?p+("<"+A.fQ(o,b)+">"):p}if(l===10)return A.iR(a,b)
if(l===11)return A.fF(a,b,null)
if(l===12)return A.fF(a.x,b,a.y)
if(l===13){n=a.x
m=b.length
n=m-1-n
if(!(n>=0&&n<m))return A.e(b,n)
return b[n]}return"?"},
j0(a){var s=v.mangledGlobalNames[a]
if(s!=null)return s
return"minified:"+a},
ih(a,b){var s=a.tR[b]
for(;typeof s=="string";)s=a.tR[s]
return s},
ig(a,b){var s,r,q,p,o,n=a.eT,m=n[b]
if(m==null)return A.dP(a,b,!1)
else if(typeof m=="number"){s=m
r=A.bZ(a,5,"#")
q=A.dR(s)
for(p=0;p<s;++p)q[p]=r
o=A.bY(a,b,q)
n[b]=o
return o}else return m},
id(a,b){return A.fA(a.tR,b)},
ic(a,b){return A.fA(a.eT,b)},
dP(a,b,c){var s,r=a.eC,q=r.get(b)
if(q!=null)return q
s=A.ft(A.fr(a,null,b,!1))
r.set(b,s)
return s},
dQ(a,b,c){var s,r,q=b.z
if(q==null)q=b.z=new Map()
s=q.get(c)
if(s!=null)return s
r=A.ft(A.fr(a,b,c,!0))
q.set(c,r)
return r},
ie(a,b,c){var s,r,q,p=b.Q
if(p==null)p=b.Q=new Map()
s=c.as
r=p.get(s)
if(r!=null)return r
q=A.eG(a,b,c.w===9?c.y:[c])
p.set(s,q)
return q},
aq(a,b){b.a=A.ix
b.b=A.iy
return b},
bZ(a,b,c){var s,r,q=a.eC.get(c)
if(q!=null)return q
s=new A.a0(null,null)
s.w=b
s.as=c
r=A.aq(a,s)
a.eC.set(c,r)
return r},
fy(a,b,c){var s,r=b.as+"?",q=a.eC.get(r)
if(q!=null)return q
s=A.ia(a,b,r,c)
a.eC.set(r,s)
return s},
ia(a,b,c,d){var s,r,q
if(d){s=b.w
r=!0
if(!A.aN(b))if(!(b===t.P||b===t.u))if(s!==6)r=s===7&&A.bc(b.x)
if(r)return b
else if(s===1)return t.P}q=new A.a0(null,null)
q.w=6
q.x=b
q.as=c
return A.aq(a,q)},
fx(a,b,c){var s,r=b.as+"/",q=a.eC.get(r)
if(q!=null)return q
s=A.i8(a,b,r,c)
a.eC.set(r,s)
return s},
i8(a,b,c,d){var s,r
if(d){s=b.w
if(A.aN(b)||b===t.K)return b
else if(s===1)return A.bY(a,"a_",[b])
else if(b===t.P||b===t.u)return t.bc}r=new A.a0(null,null)
r.w=7
r.x=b
r.as=c
return A.aq(a,r)},
ib(a,b){var s,r,q=""+b+"^",p=a.eC.get(q)
if(p!=null)return p
s=new A.a0(null,null)
s.w=13
s.x=b
s.as=q
r=A.aq(a,s)
a.eC.set(q,r)
return r},
bX(a){var s,r,q,p=a.length
for(s="",r="",q=0;q<p;++q,r=",")s+=r+a[q].as
return s},
i7(a){var s,r,q,p,o,n=a.length
for(s="",r="",q=0;q<n;q+=3,r=","){p=a[q]
o=a[q+1]?"!":":"
s+=r+p+o+a[q+2].as}return s},
bY(a,b,c){var s,r,q,p=b
if(c.length>0)p+="<"+A.bX(c)+">"
s=a.eC.get(p)
if(s!=null)return s
r=new A.a0(null,null)
r.w=8
r.x=b
r.y=c
if(c.length>0)r.c=c[0]
r.as=p
q=A.aq(a,r)
a.eC.set(p,q)
return q},
eG(a,b,c){var s,r,q,p,o,n
if(b.w===9){s=b.x
r=b.y.concat(c)}else{r=c
s=b}q=s.as+(";<"+A.bX(r)+">")
p=a.eC.get(q)
if(p!=null)return p
o=new A.a0(null,null)
o.w=9
o.x=s
o.y=r
o.as=q
n=A.aq(a,o)
a.eC.set(q,n)
return n},
fz(a,b,c){var s,r,q="+"+(b+"("+A.bX(c)+")"),p=a.eC.get(q)
if(p!=null)return p
s=new A.a0(null,null)
s.w=10
s.x=b
s.y=c
s.as=q
r=A.aq(a,s)
a.eC.set(q,r)
return r},
fw(a,b,c){var s,r,q,p,o,n=b.as,m=c.a,l=m.length,k=c.b,j=k.length,i=c.c,h=i.length,g="("+A.bX(m)
if(j>0){s=l>0?",":""
g+=s+"["+A.bX(k)+"]"}if(h>0){s=l>0?",":""
g+=s+"{"+A.i7(i)+"}"}r=n+(g+")")
q=a.eC.get(r)
if(q!=null)return q
p=new A.a0(null,null)
p.w=11
p.x=b
p.y=c
p.as=r
o=A.aq(a,p)
a.eC.set(r,o)
return o},
eH(a,b,c,d){var s,r=b.as+("<"+A.bX(c)+">"),q=a.eC.get(r)
if(q!=null)return q
s=A.i9(a,b,c,r,d)
a.eC.set(r,s)
return s},
i9(a,b,c,d,e){var s,r,q,p,o,n,m,l
if(e){s=c.length
r=A.dR(s)
for(q=0,p=0;p<s;++p){o=c[p]
if(o.w===1){r[p]=o;++q}}if(q>0){n=A.aK(a,b,r,0)
m=A.b8(a,c,r,0)
return A.eH(a,n,m,c!==m)}}l=new A.a0(null,null)
l.w=12
l.x=b
l.y=c
l.as=d
return A.aq(a,l)},
fr(a,b,c,d){return{u:a,e:b,r:c,s:[],p:0,n:d}},
ft(a){var s,r,q,p,o,n,m,l=a.r,k=a.s
for(s=l.length,r=0;r<s;){q=l.charCodeAt(r)
if(q>=48&&q<=57)r=A.i1(r+1,q,l,k)
else if((((q|32)>>>0)-97&65535)<26||q===95||q===36||q===124)r=A.fs(a,r,l,k,!1)
else if(q===46)r=A.fs(a,r,l,k,!0)
else{++r
switch(q){case 44:break
case 58:k.push(!1)
break
case 33:k.push(!0)
break
case 59:k.push(A.aI(a.u,a.e,k.pop()))
break
case 94:k.push(A.ib(a.u,k.pop()))
break
case 35:k.push(A.bZ(a.u,5,"#"))
break
case 64:k.push(A.bZ(a.u,2,"@"))
break
case 126:k.push(A.bZ(a.u,3,"~"))
break
case 60:k.push(a.p)
a.p=k.length
break
case 62:A.i3(a,k)
break
case 38:A.i2(a,k)
break
case 63:p=a.u
k.push(A.fy(p,A.aI(p,a.e,k.pop()),a.n))
break
case 47:p=a.u
k.push(A.fx(p,A.aI(p,a.e,k.pop()),a.n))
break
case 40:k.push(-3)
k.push(a.p)
a.p=k.length
break
case 41:A.i0(a,k)
break
case 91:k.push(a.p)
a.p=k.length
break
case 93:o=k.splice(a.p)
A.fu(a.u,a.e,o)
a.p=k.pop()
k.push(o)
k.push(-1)
break
case 123:k.push(a.p)
a.p=k.length
break
case 125:o=k.splice(a.p)
A.i5(a.u,a.e,o)
a.p=k.pop()
k.push(o)
k.push(-2)
break
case 43:n=l.indexOf("(",r)
k.push(l.substring(r,n))
k.push(-4)
k.push(a.p)
a.p=k.length
r=n+1
break
default:throw"Bad character "+q}}}m=k.pop()
return A.aI(a.u,a.e,m)},
i1(a,b,c,d){var s,r,q=b-48
for(s=c.length;a<s;++a){r=c.charCodeAt(a)
if(!(r>=48&&r<=57))break
q=q*10+(r-48)}d.push(q)
return a},
fs(a,b,c,d,e){var s,r,q,p,o,n,m=b+1
for(s=c.length;m<s;++m){r=c.charCodeAt(m)
if(r===46){if(e)break
e=!0}else{if(!((((r|32)>>>0)-97&65535)<26||r===95||r===36||r===124))q=r>=48&&r<=57
else q=!0
if(!q)break}}p=c.substring(b,m)
if(e){s=a.u
o=a.e
if(o.w===9)o=o.x
n=A.ih(s,o.x)[p]
if(n==null)A.W('No "'+p+'" in "'+A.hO(o)+'"')
d.push(A.dQ(s,o,n))}else d.push(p)
return m},
i3(a,b){var s,r=a.u,q=A.fq(a,b),p=b.pop()
if(typeof p=="string")b.push(A.bY(r,p,q))
else{s=A.aI(r,a.e,p)
switch(s.w){case 11:b.push(A.eH(r,s,q,a.n))
break
default:b.push(A.eG(r,s,q))
break}}},
i0(a,b){var s,r,q,p=a.u,o=b.pop(),n=null,m=null
if(typeof o=="number")switch(o){case-1:n=b.pop()
break
case-2:m=b.pop()
break
default:b.push(o)
break}else b.push(o)
s=A.fq(a,b)
o=b.pop()
switch(o){case-3:o=b.pop()
if(n==null)n=p.sEA
if(m==null)m=p.sEA
r=A.aI(p,a.e,o)
q=new A.cG()
q.a=s
q.b=n
q.c=m
b.push(A.fw(p,r,q))
return
case-4:b.push(A.fz(p,b.pop(),s))
return
default:throw A.d(A.c4("Unexpected state under `()`: "+A.c(o)))}},
i2(a,b){var s=b.pop()
if(0===s){b.push(A.bZ(a.u,1,"0&"))
return}if(1===s){b.push(A.bZ(a.u,4,"1&"))
return}throw A.d(A.c4("Unexpected extended operation "+A.c(s)))},
fq(a,b){var s=b.splice(a.p)
A.fu(a.u,a.e,s)
a.p=b.pop()
return s},
aI(a,b,c){if(typeof c=="string")return A.bY(a,c,a.sEA)
else if(typeof c=="number"){b.toString
return A.i4(a,b,c)}else return c},
fu(a,b,c){var s,r=c.length
for(s=0;s<r;++s)c[s]=A.aI(a,b,c[s])},
i5(a,b,c){var s,r=c.length
for(s=2;s<r;s+=3)c[s]=A.aI(a,b,c[s])},
i4(a,b,c){var s,r,q=b.w
if(q===9){if(c===0)return b.x
s=b.y
r=s.length
if(c<=r)return s[c-1]
c-=r
b=b.x
q=b.w}else if(c===0)return b
if(q!==8)throw A.d(A.c4("Indexed base must be an interface type"))
s=b.y
if(c<=s.length)return s[c-1]
throw A.d(A.c4("Bad index "+c+" for "+b.k(0)))},
jm(a,b,c){var s,r=b.d
if(r==null)r=b.d=new Map()
s=r.get(c)
if(s==null){s=A.A(a,b,null,c,null)
r.set(c,s)}return s},
A(a,b,c,d,e){var s,r,q,p,o,n,m,l,k,j,i
if(b===d)return!0
if(A.aN(d))return!0
s=b.w
if(s===4)return!0
if(A.aN(b))return!1
if(b.w===1)return!0
r=s===13
if(r)if(A.A(a,c[b.x],c,d,e))return!0
q=d.w
p=t.P
if(b===p||b===t.u){if(q===7)return A.A(a,b,c,d.x,e)
return d===p||d===t.u||q===6}if(d===t.K){if(s===7)return A.A(a,b.x,c,d,e)
return s!==6}if(s===7){if(!A.A(a,b.x,c,d,e))return!1
return A.A(a,A.eC(a,b),c,d,e)}if(s===6)return A.A(a,p,c,d,e)&&A.A(a,b.x,c,d,e)
if(q===7){if(A.A(a,b,c,d.x,e))return!0
return A.A(a,b,c,A.eC(a,d),e)}if(q===6)return A.A(a,b,c,p,e)||A.A(a,b,c,d.x,e)
if(r)return!1
p=s!==11
if((!p||s===12)&&d===t.Z)return!0
o=s===10
if(o&&d===t.cY)return!0
if(q===12){if(b===t.g)return!0
if(s!==12)return!1
n=b.y
m=d.y
l=n.length
if(l!==m.length)return!1
c=c==null?n:n.concat(c)
e=e==null?m:m.concat(e)
for(k=0;k<l;++k){j=n[k]
i=m[k]
if(!A.A(a,j,c,i,e)||!A.A(a,i,e,j,c))return!1}return A.fI(a,b.x,c,d.x,e)}if(q===11){if(b===t.g)return!0
if(p)return!1
return A.fI(a,b,c,d,e)}if(s===8){if(q!==8)return!1
return A.iE(a,b,c,d,e)}if(o&&q===10)return A.iJ(a,b,c,d,e)
return!1},
fI(a3,a4,a5,a6,a7){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2
if(!A.A(a3,a4.x,a5,a6.x,a7))return!1
s=a4.y
r=a6.y
q=s.a
p=r.a
o=q.length
n=p.length
if(o>n)return!1
m=n-o
l=s.b
k=r.b
j=l.length
i=k.length
if(o+j<n+i)return!1
for(h=0;h<o;++h){g=q[h]
if(!A.A(a3,p[h],a7,g,a5))return!1}for(h=0;h<m;++h){g=l[h]
if(!A.A(a3,p[o+h],a7,g,a5))return!1}for(h=0;h<i;++h){g=l[m+h]
if(!A.A(a3,k[h],a7,g,a5))return!1}f=s.c
e=r.c
d=f.length
c=e.length
for(b=0,a=0;a<c;a+=3){a0=e[a]
for(;!0;){if(b>=d)return!1
a1=f[b]
b+=3
if(a0<a1)return!1
a2=f[b-2]
if(a1<a0){if(a2)return!1
continue}g=e[a+1]
if(a2&&!g)return!1
g=f[b-1]
if(!A.A(a3,e[a+2],a7,g,a5))return!1
break}}for(;b<d;){if(f[b+1])return!1
b+=3}return!0},
iE(a,b,c,d,e){var s,r,q,p,o,n=b.x,m=d.x
for(;n!==m;){s=a.tR[n]
if(s==null)return!1
if(typeof s=="string"){n=s
continue}r=s[m]
if(r==null)return!1
q=r.length
p=q>0?new Array(q):v.typeUniverse.sEA
for(o=0;o<q;++o)p[o]=A.dQ(a,b,r[o])
return A.fB(a,p,null,c,d.y,e)}return A.fB(a,b.y,null,c,d.y,e)},
fB(a,b,c,d,e,f){var s,r=b.length
for(s=0;s<r;++s)if(!A.A(a,b[s],d,e[s],f))return!1
return!0},
iJ(a,b,c,d,e){var s,r=b.y,q=d.y,p=r.length
if(p!==q.length)return!1
if(b.x!==d.x)return!1
for(s=0;s<p;++s)if(!A.A(a,r[s],c,q[s],e))return!1
return!0},
bc(a){var s=a.w,r=!0
if(!(a===t.P||a===t.u))if(!A.aN(a))if(s!==6)r=s===7&&A.bc(a.x)
return r},
aN(a){var s=a.w
return s===2||s===3||s===4||s===5||a===t.X},
fA(a,b){var s,r,q=Object.keys(b),p=q.length
for(s=0;s<p;++s){r=q[s]
a[r]=b[r]}},
dR(a){return a>0?new Array(a):v.typeUniverse.sEA},
a0:function a0(a,b){var _=this
_.a=a
_.b=b
_.r=_.f=_.d=_.c=null
_.w=0
_.as=_.Q=_.z=_.y=_.x=null},
cG:function cG(){this.c=this.b=this.a=null},
dO:function dO(a){this.a=a},
cF:function cF(){},
bW:function bW(a){this.a=a},
hS(){var s,r,q
if(self.scheduleImmediate!=null)return A.j3()
if(self.MutationObserver!=null&&self.document!=null){s={}
r=self.document.createElement("div")
q=self.document.createElement("span")
s.a=null
new self.MutationObserver(A.c2(new A.dq(s),1)).observe(r,{childList:true})
return new A.dp(s,r,q)}else if(self.setImmediate!=null)return A.j4()
return A.j5()},
hT(a){self.scheduleImmediate(A.c2(new A.dr(t.M.a(a)),0))},
hU(a){self.setImmediate(A.c2(new A.ds(t.M.a(a)),0))},
hV(a){t.M.a(a)
A.i6(0,a)},
i6(a,b){var s=new A.dM()
s.be(a,b)
return s},
G(a){return new A.cC(new A.x($.t,a.h("x<0>")),a.h("cC<0>"))},
F(a,b){a.$2(0,null)
b.b=!0
return b.a},
m(a,b){A.io(a,b)},
E(a,b){b.an(a)},
D(a,b){b.ao(A.M(a),A.aM(a))},
io(a,b){var s,r,q=new A.dT(b),p=new A.dU(b)
if(a instanceof A.x)a.aU(q,p,t.z)
else{s=t.z
if(a instanceof A.x)a.b6(q,p,s)
else{r=new A.x($.t,t._)
r.a=8
r.c=a
r.aU(q,p,s)}}},
H(a){var s=function(b,c){return function(d,e){while(true){try{b(d,e)
break}catch(r){e=r
d=c}}}}(a,1)
return $.t.av(new A.dX(s),t.H,t.S,t.z)},
ey(a){var s
if(t.C.b(a)){s=a.gO()
if(s!=null)return s}return B.o},
iA(a,b){if($.t===B.h)return null
return null},
iB(a,b){if($.t!==B.h)A.iA(a,b)
if(b==null)if(t.C.b(a)){b=a.gO()
if(b==null){A.fc(a,B.o)
b=B.o}}else b=B.o
else if(t.C.b(a))A.fc(a,b)
return new A.O(a,b)},
eD(a,b,c){var s,r,q,p,o={},n=o.a=a
for(s=t._;r=n.a,(r&4)!==0;n=a){a=s.a(n.c)
o.a=a}if(n===b){s=A.fg()
b.ad(new A.O(new A.Z(!0,n,null,"Cannot complete a future with itself"),s))
return}q=b.a&1
s=n.a=r|q
if((s&24)===0){p=t.F.a(b.c)
b.a=b.a&1|4
b.c=n
n.aS(p)
return}if(!c)if(b.c==null)n=(s&16)===0||q!==0
else n=!1
else n=!0
if(n){p=b.P()
b.Z(o.a)
A.aH(b,p)
return}b.a^=2
A.b7(null,null,b.b,t.M.a(new A.dA(o,b)))},
aH(a,b){var s,r,q,p,o,n,m,l,k,j,i,h,g,f,e,d={},c=d.a=a
for(s=t.n,r=t.F;!0;){q={}
p=c.a
o=(p&16)===0
n=!o
if(b==null){if(n&&(p&1)===0){m=s.a(c.c)
A.cN(m.a,m.b)}return}q.a=b
l=b.a
for(c=b;l!=null;c=l,l=k){c.a=null
A.aH(d.a,c)
q.a=l
k=l.a}p=d.a
j=p.c
q.b=n
q.c=j
if(o){i=c.c
i=(i&1)!==0||(i&15)===8}else i=!0
if(i){h=c.b.b
if(n){p=p.b===h
p=!(p||p)}else p=!1
if(p){s.a(j)
A.cN(j.a,j.b)
return}g=$.t
if(g!==h)$.t=h
else g=null
c=c.c
if((c&15)===8)new A.dE(q,d,n).$0()
else if(o){if((c&1)!==0)new A.dD(q,j).$0()}else if((c&2)!==0)new A.dC(d,q).$0()
if(g!=null)$.t=g
c=q.c
if(c instanceof A.x){p=q.a.$ti
p=p.h("a_<2>").b(c)||!p.y[1].b(c)}else p=!1
if(p){f=q.a.b
if((c.a&24)!==0){e=r.a(f.c)
f.c=null
b=f.a1(e)
f.a=c.a&30|f.a&1
f.c=c.c
d.a=c
continue}else A.eD(c,f,!0)
return}}f=q.a.b
e=r.a(f.c)
f.c=null
b=f.a1(e)
c=q.b
p=q.c
if(!c){f.$ti.c.a(p)
f.a=8
f.c=p}else{s.a(p)
f.a=f.a&1|16
f.c=p}d.a=f
c=f}},
iS(a,b){var s
if(t.Q.b(a))return b.av(a,t.z,t.K,t.l)
s=t.v
if(s.b(a))return s.a(a)
throw A.d(A.ex(a,"onError",u.c))},
iO(){var s,r
for(s=$.b6;s!=null;s=$.b6){$.c1=null
r=s.b
$.b6=r
if(r==null)$.c0=null
s.a.$0()}},
iX(){$.eK=!0
try{A.iO()}finally{$.c1=null
$.eK=!1
if($.b6!=null)$.eS().$1(A.fU())}},
fS(a){var s=new A.cD(a),r=$.c0
if(r==null){$.b6=$.c0=s
if(!$.eK)$.eS().$1(A.fU())}else $.c0=r.b=s},
iU(a){var s,r,q,p=$.b6
if(p==null){A.fS(a)
$.c1=$.c0
return}s=new A.cD(a)
r=$.c1
if(r==null){s.b=p
$.b6=$.c1=s}else{q=r.b
s.b=q
$.c1=r.b=s
if(q==null)$.c0=s}},
h2(a){var s=null,r=$.t
if(B.h===r){A.b7(s,s,B.h,a)
return}A.b7(s,s,r,t.M.a(r.aW(a)))},
jA(a,b){A.dY(a,"stream",t.K)
return new A.cJ(b.h("cJ<0>"))},
fR(a){return},
i_(a,b){if(b==null)b=A.j7()
if(t.aD.b(b))return a.av(b,t.z,t.K,t.l)
if(t.bo.b(b))return t.v.a(b)
throw A.d(A.ai("handleError callback must take either an Object (the error), or both an Object (the error) and a StackTrace.",null))},
iQ(a,b){A.cN(a,b)},
iP(){},
cN(a,b){A.iU(new A.dW(a,b))},
fO(a,b,c,d,e){var s,r=$.t
if(r===c)return d.$0()
$.t=c
s=r
try{r=d.$0()
return r}finally{$.t=s}},
fP(a,b,c,d,e,f,g){var s,r=$.t
if(r===c)return d.$1(e)
$.t=c
s=r
try{r=d.$1(e)
return r}finally{$.t=s}},
iT(a,b,c,d,e,f,g,h,i){var s,r=$.t
if(r===c)return d.$2(e,f)
$.t=c
s=r
try{r=d.$2(e,f)
return r}finally{$.t=s}},
b7(a,b,c,d){t.M.a(d)
if(B.h!==c){d=c.aW(d)
d=d}A.fS(d)},
dq:function dq(a){this.a=a},
dp:function dp(a,b,c){this.a=a
this.b=b
this.c=c},
dr:function dr(a){this.a=a},
ds:function ds(a){this.a=a},
dM:function dM(){},
dN:function dN(a,b){this.a=a
this.b=b},
cC:function cC(a,b){this.a=a
this.b=!1
this.$ti=b},
dT:function dT(a){this.a=a},
dU:function dU(a){this.a=a},
dX:function dX(a){this.a=a},
O:function O(a,b){this.a=a
this.b=b},
b1:function b1(a,b){this.a=a
this.$ti=b},
ao:function ao(a,b,c,d,e){var _=this
_.ay=0
_.CW=_.ch=null
_.w=a
_.a=b
_.d=c
_.e=d
_.r=null
_.$ti=e},
aF:function aF(){},
bV:function bV(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.e=_.d=null
_.$ti=c},
dL:function dL(a,b){this.a=a
this.b=b},
cE:function cE(){},
bI:function bI(a,b){this.a=a
this.$ti=b},
aG:function aG(a,b,c,d,e){var _=this
_.a=null
_.b=a
_.c=b
_.d=c
_.e=d
_.$ti=e},
x:function x(a,b){var _=this
_.a=0
_.b=a
_.c=null
_.$ti=b},
dx:function dx(a,b){this.a=a
this.b=b},
dB:function dB(a,b){this.a=a
this.b=b},
dA:function dA(a,b){this.a=a
this.b=b},
dz:function dz(a,b){this.a=a
this.b=b},
dy:function dy(a,b){this.a=a
this.b=b},
dE:function dE(a,b,c){this.a=a
this.b=b
this.c=c},
dF:function dF(a,b){this.a=a
this.b=b},
dG:function dG(a){this.a=a},
dD:function dD(a,b){this.a=a
this.b=b},
dC:function dC(a,b){this.a=a
this.b=b},
cD:function cD(a){this.a=a
this.b=null},
b_:function b_(){},
dh:function dh(a,b){this.a=a
this.b=b},
di:function di(a,b){this.a=a
this.b=b},
bJ:function bJ(){},
bK:function bK(){},
ad:function ad(){},
b5:function b5(){},
bM:function bM(){},
bL:function bL(a,b){this.b=a
this.a=null
this.$ti=b},
cH:function cH(a){var _=this
_.a=0
_.c=_.b=null
_.$ti=a},
dJ:function dJ(a,b){this.a=a
this.b=b},
b3:function b3(a,b){var _=this
_.a=1
_.b=a
_.c=null
_.$ti=b},
cJ:function cJ(a){this.$ti=a},
c_:function c_(){},
dW:function dW(a,b){this.a=a
this.b=b},
cI:function cI(){},
dK:function dK(a,b){this.a=a
this.b=b},
fp(a,b){var s=a[b]
return s===a?null:s},
eF(a,b,c){if(c==null)a[b]=a
else a[b]=c},
eE(){var s=Object.create(null)
A.eF(s,"<non-identifier-key>",s)
delete s["<non-identifier-key>"]
return s},
j(a,b,c){return b.h("@<0>").l(c).h("f3<1,2>").a(A.jb(a,new A.az(b.h("@<0>").l(c).h("az<1,2>"))))},
br(a,b){return new A.az(a.h("@<0>").l(b).h("az<1,2>"))},
f7(a){var s,r
if(A.eO(a))return"{...}"
s=new A.cx("")
try{r={}
B.d.u($.S,a)
s.a+="{"
r.a=!0
a.aq(0,new A.db(r,s))
s.a+="}"}finally{if(0>=$.S.length)return A.e($.S,-1)
$.S.pop()}r=s.a
return r.charCodeAt(0)==0?r:r},
bN:function bN(){},
b4:function b4(a){var _=this
_.a=0
_.e=_.d=_.c=_.b=null
_.$ti=a},
bO:function bO(a,b){this.a=a
this.$ti=b},
bP:function bP(a,b,c){var _=this
_.a=a
_.b=b
_.c=0
_.d=null
_.$ti=c},
u:function u(){},
aC:function aC(){},
db:function db(a,b){this.a=a
this.b=b},
hZ(a,b,c,d,e,f,g,a0){var s,r,q,p,o,n,m,l,k,j,i=a0>>>2,h=3-(a0&3)
for(s=b.length,r=a.length,q=f.$flags|0,p=c,o=0;p<d;++p){if(!(p<s))return A.e(b,p)
n=b[p]
o|=n
i=(i<<8|n)&16777215;--h
if(h===0){m=g+1
l=i>>>18&63
if(!(l<r))return A.e(a,l)
q&2&&A.X(f)
k=f.length
if(!(g<k))return A.e(f,g)
f[g]=a.charCodeAt(l)
g=m+1
l=i>>>12&63
if(!(l<r))return A.e(a,l)
if(!(m<k))return A.e(f,m)
f[m]=a.charCodeAt(l)
m=g+1
l=i>>>6&63
if(!(l<r))return A.e(a,l)
if(!(g<k))return A.e(f,g)
f[g]=a.charCodeAt(l)
g=m+1
l=i&63
if(!(l<r))return A.e(a,l)
if(!(m<k))return A.e(f,m)
f[m]=a.charCodeAt(l)
i=0
h=3}}if(o>=0&&o<=255){if(h<3){m=g+1
j=m+1
if(3-h===1){s=i>>>2&63
if(!(s<r))return A.e(a,s)
q&2&&A.X(f)
q=f.length
if(!(g<q))return A.e(f,g)
f[g]=a.charCodeAt(s)
s=i<<4&63
if(!(s<r))return A.e(a,s)
if(!(m<q))return A.e(f,m)
f[m]=a.charCodeAt(s)
g=j+1
if(!(j<q))return A.e(f,j)
f[j]=61
if(!(g<q))return A.e(f,g)
f[g]=61}else{s=i>>>10&63
if(!(s<r))return A.e(a,s)
q&2&&A.X(f)
q=f.length
if(!(g<q))return A.e(f,g)
f[g]=a.charCodeAt(s)
s=i>>>4&63
if(!(s<r))return A.e(a,s)
if(!(m<q))return A.e(f,m)
f[m]=a.charCodeAt(s)
g=j+1
s=i<<2&63
if(!(s<r))return A.e(a,s)
if(!(j<q))return A.e(f,j)
f[j]=a.charCodeAt(s)
if(!(g<q))return A.e(f,g)
f[g]=61}return 0}return(i<<2|3-h)>>>0}for(p=c;p<d;){if(!(p<s))return A.e(b,p)
n=b[p]
if(n>255)break;++p}if(!(p<s))return A.e(b,p)
throw A.d(A.ex(b,"Not a byte value at index "+p+": 0x"+B.i.bV(b[p],16),null))},
hY(a,b,c,d,a0,a1){var s,r,q,p,o,n,m,l,k,j,i="Invalid encoding before padding",h="Invalid character",g=B.i.a3(a1,2),f=a1&3,e=$.hf()
for(s=a.length,r=e.length,q=d.$flags|0,p=b,o=0;p<c;++p){if(!(p<s))return A.e(a,p)
n=a.charCodeAt(p)
o|=n
m=n&127
if(!(m<r))return A.e(e,m)
l=e[m]
if(l>=0){g=(g<<6|l)&16777215
f=f+1&3
if(f===0){k=a0+1
q&2&&A.X(d)
m=d.length
if(!(a0<m))return A.e(d,a0)
d[a0]=g>>>16&255
a0=k+1
if(!(k<m))return A.e(d,k)
d[k]=g>>>8&255
k=a0+1
if(!(a0<m))return A.e(d,a0)
d[a0]=g&255
a0=k
g=0}continue}else if(l===-1&&f>1){if(o>127)break
if(f===3){if((g&3)!==0)throw A.d(A.aS(i,a,p))
k=a0+1
q&2&&A.X(d)
s=d.length
if(!(a0<s))return A.e(d,a0)
d[a0]=g>>>10
if(!(k<s))return A.e(d,k)
d[k]=g>>>2}else{if((g&15)!==0)throw A.d(A.aS(i,a,p))
q&2&&A.X(d)
if(!(a0<d.length))return A.e(d,a0)
d[a0]=g>>>4}j=(3-f)*3
if(n===37)j+=2
return A.fn(a,p+1,c,-j-1)}throw A.d(A.aS(h,a,p))}if(o>=0&&o<=127)return(g<<2|f)>>>0
for(p=b;p<c;++p){if(!(p<s))return A.e(a,p)
if(a.charCodeAt(p)>127)break}throw A.d(A.aS(h,a,p))},
hW(a,b,c,d){var s=A.hX(a,b,c),r=(d&3)+(s-b),q=B.i.a3(r,2)*3,p=r&3
if(p!==0&&s<c)q+=p-1
if(q>0)return new Uint8Array(q)
return $.he()},
hX(a,b,c){var s,r=a.length,q=c,p=q,o=0
while(!0){if(!(p>b&&o<2))break
c$0:{--p
if(!(p>=0&&p<r))return A.e(a,p)
s=a.charCodeAt(p)
if(s===61){++o
q=p
break c$0}if((s|32)===100){if(p===b)break;--p
if(!(p>=0&&p<r))return A.e(a,p)
s=a.charCodeAt(p)}if(s===51){if(p===b)break;--p
if(!(p>=0&&p<r))return A.e(a,p)
s=a.charCodeAt(p)}if(s===37){++o
q=p
break c$0}break}}return q},
fn(a,b,c,d){var s,r,q
if(b===c)return d
s=-d-1
for(r=a.length;s>0;){if(!(b<r))return A.e(a,b)
q=a.charCodeAt(b)
if(s===3){if(q===61){s-=3;++b
break}if(q===37){--s;++b
if(b===c)break
if(!(b<r))return A.e(a,b)
q=a.charCodeAt(b)}else break}if((s>3?s-3:s)===2){if(q!==51)break;++b;--s
if(b===c)break
if(!(b<r))return A.e(a,b)
q=a.charCodeAt(b)}if((q|32)!==100)break;++b;--s
if(b===c)break}if(b!==c)throw A.d(A.aS("Invalid padding character",a,b))
return-s-1},
c5:function c5(){},
cT:function cT(){},
du:function du(a){this.a=0
this.b=a},
cS:function cS(){},
dt:function dt(){this.a=0},
av:function av(){},
c9:function c9(){},
ht(a,b){a=A.B(a,new Error())
if(a==null)a=A.J(a)
a.stack=b.k(0)
throw a},
f5(a,b,c,d){var s,r=J.hw(a,d)
if(a!==0&&b!=null)for(s=0;s<a;++s)r[s]=b
return r},
f4(a,b){var s,r=A.N([],b.h("z<0>"))
for(s=J.ev(a);s.p();)B.d.u(r,s.gn())
return r},
hP(a){var s
A.fd(0,"start")
s=A.hQ(a,0,null)
return s},
hQ(a,b,c){var s=a.length
if(b>=s)return""
return A.hM(a,b,s)},
fi(a,b,c){var s=J.ev(b)
if(!s.p())return a
if(c.length===0){do a+=A.c(s.gn())
while(s.p())}else{a+=A.c(s.gn())
for(;s.p();)a=a+c+A.c(s.gn())}return a},
fg(){return A.aM(new Error())},
hs(a){var s=Math.abs(a),r=a<0?"-":""
if(s>=1000)return""+a
if(s>=100)return r+"0"+s
if(s>=10)return r+"00"+s
return r+"000"+s},
f1(a){if(a>=100)return""+a
if(a>=10)return"0"+a
return"00"+a},
cb(a){if(a>=10)return""+a
return"0"+a},
cW(a){if(typeof a=="number"||A.dV(a)||a==null)return J.T(a)
if(typeof a=="string")return JSON.stringify(a)
return A.hL(a)},
hu(a,b){A.dY(a,"error",t.K)
A.dY(b,"stackTrace",t.l)
A.ht(a,b)},
c4(a){return new A.c3(a)},
ai(a,b){return new A.Z(!1,null,b,a)},
ex(a,b,c){return new A.Z(!0,a,b,c)},
hN(a,b){return new A.aZ(null,null,!0,a,b,"Value not in range")},
aa(a,b,c,d,e){return new A.aZ(b,c,!0,a,d,"Invalid value")},
fe(a,b,c){if(0>a||a>c)throw A.d(A.aa(a,0,c,"start",null))
if(b!=null){if(a>b||b>c)throw A.d(A.aa(b,a,c,"end",null))
return b}return c},
fd(a,b){if(a<0)throw A.d(A.aa(a,0,null,b,null))
return a},
f2(a,b,c,d){return new A.cc(b,!0,a,d,"Index out of range")},
bG(a){return new A.bF(a)},
fl(a){return new A.cA(a)},
dg(a){return new A.aD(a)},
bh(a){return new A.c8(a)},
a3(a){return new A.dw(a)},
aS(a,b,c){return new A.cZ(a,b,c)},
hv(a,b,c){var s,r
if(A.eO(a)){if(b==="("&&c===")")return"(...)"
return b+"..."+c}s=A.N([],t.s)
B.d.u($.S,a)
try{A.iN(a,s)}finally{if(0>=$.S.length)return A.e($.S,-1)
$.S.pop()}r=A.fi(b,t.R.a(s),", ")+c
return r.charCodeAt(0)==0?r:r},
d5(a,b,c){var s,r
if(A.eO(a))return b+"..."+c
s=new A.cx(b)
B.d.u($.S,a)
try{r=s
r.a=A.fi(r.a,a,", ")}finally{if(0>=$.S.length)return A.e($.S,-1)
$.S.pop()}s.a+=c
r=s.a
return r.charCodeAt(0)==0?r:r},
iN(a,b){var s,r,q,p,o,n,m,l=a.gA(a),k=0,j=0
while(!0){if(!(k<80||j<3))break
if(!l.p())return
s=A.c(l.gn())
B.d.u(b,s)
k+=s.length+2;++j}if(!l.p()){if(j<=5)return
if(0>=b.length)return A.e(b,-1)
r=b.pop()
if(0>=b.length)return A.e(b,-1)
q=b.pop()}else{p=l.gn();++j
if(!l.p()){if(j<=4){B.d.u(b,A.c(p))
return}r=A.c(p)
if(0>=b.length)return A.e(b,-1)
q=b.pop()
k+=r.length+2}else{o=l.gn();++j
for(;l.p();p=o,o=n){n=l.gn();++j
if(j>100){while(!0){if(!(k>75&&j>3))break
if(0>=b.length)return A.e(b,-1)
k-=b.pop().length+2;--j}B.d.u(b,"...")
return}}q=A.c(p)
r=A.c(o)
k+=r.length+q.length+4}}if(j>b.length+2){k+=5
m="..."}else m=null
while(!0){if(!(k>80&&b.length>3))break
if(0>=b.length)return A.e(b,-1)
k-=b.pop().length+2
if(m==null){k+=5
m="..."}}if(m!=null)B.d.u(b,m)
B.d.u(b,q)
B.d.u(b,r)},
hC(a,b){var s=B.i.gt(a)
b=B.i.gt(b)
b=A.hR(A.fj(A.fj($.hg(),s),b))
return b},
ca:function ca(a,b,c){this.a=a
this.b=b
this.c=c},
dv:function dv(){},
w:function w(){},
c3:function c3(a){this.a=a},
ab:function ab(){},
Z:function Z(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
aZ:function aZ(a,b,c,d,e,f){var _=this
_.e=a
_.f=b
_.a=c
_.b=d
_.c=e
_.d=f},
cc:function cc(a,b,c,d,e){var _=this
_.f=a
_.a=b
_.b=c
_.c=d
_.d=e},
bF:function bF(a){this.a=a},
cA:function cA(a){this.a=a},
aD:function aD(a){this.a=a},
c8:function c8(a){this.a=a},
cr:function cr(){},
bD:function bD(){},
dw:function dw(a){this.a=a},
cZ:function cZ(a,b,c){this.a=a
this.b=b
this.c=c},
f:function f(){},
y:function y(){},
k:function k(){},
cK:function cK(){},
cx:function cx(a){this.a=a},
fG(a){var s
if(typeof a=="function")throw A.d(A.ai("Attempting to rewrap a JS function.",null))
s=function(b,c){return function(d){return b(c,d,arguments.length)}}(A.ip,a)
s[$.er()]=a
return s},
fH(a){var s
if(typeof a=="function")throw A.d(A.ai("Attempting to rewrap a JS function.",null))
s=function(b,c){return function(d,e){return b(c,d,e,arguments.length)}}(A.iq,a)
s[$.er()]=a
return s},
ip(a,b,c){t.Z.a(a)
if(A.p(c)>=1)return a.$1(b)
return a.$0()},
iq(a,b,c,d){t.Z.a(a)
A.p(d)
if(d>=2)return a.$2(b,c)
if(d===1)return a.$1(b)
return a.$0()},
fN(a){return a==null||A.dV(a)||typeof a=="number"||typeof a=="string"||t.U.b(a)||t.p.b(a)||t.ca.b(a)||t.O.b(a)||t.c0.b(a)||t.k.b(a)||t.bk.b(a)||t.G.b(a)||t.q.b(a)||t.J.b(a)||t.V.b(a)},
i(a){if(A.fN(a))return a
return new A.ea(new A.b4(t.A)).$1(a)},
eL(a,b,c,d){return d.a(a[b].apply(a,c))},
ag(a,b){var s=new A.x($.t,b.h("x<0>")),r=new A.bI(s,b.h("bI<0>"))
a.then(A.c2(new A.en(r,b),1),A.c2(new A.eo(r),1))
return s},
fM(a){return a==null||typeof a==="boolean"||typeof a==="number"||typeof a==="string"||a instanceof Int8Array||a instanceof Uint8Array||a instanceof Uint8ClampedArray||a instanceof Int16Array||a instanceof Uint16Array||a instanceof Int32Array||a instanceof Uint32Array||a instanceof Float32Array||a instanceof Float64Array||a instanceof ArrayBuffer||a instanceof DataView},
fW(a){if(A.fM(a))return a
return new A.dZ(new A.b4(t.A)).$1(a)},
ea:function ea(a){this.a=a},
en:function en(a,b){this.a=a
this.b=b},
eo:function eo(a){this.a=a},
dZ:function dZ(a){this.a=a},
dc:function dc(a){this.a=a},
dH:function dH(a){this.a=a},
am:function am(a,b){this.a=a
this.b=b},
aB:function aB(a,b,c){this.a=a
this.b=b
this.d=c},
d9(a){return $.hz.bP(a,new A.da(a))},
aX:function aX(a,b,c){var _=this
_.a=a
_.b=b
_.c=null
_.d=c
_.f=null},
da:function da(a){this.a=a},
ah:function ah(a){this.b=a},
bj:function bj(a,b,c){this.a=a
this.b=b
this.c=c},
aw:function aw(a,b,c,d){var _=this
_.a=-1
_.b=a
_.c=b
_.d=c
_.f=d},
cU:function cU(a,b,c,d,e,f){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f},
cV:function cV(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
jc(a){var s,r,q,p,o=A.N([],t.t),n=a.length,m=n-2
for(s=0,r=0;r<m;s=r){while(!0){if(r<m){if(!(r>=0))return A.e(a,r)
q=!(a[r]===0&&a[r+1]===0&&a[r+2]===1)}else q=!1
if(!q)break;++r}if(r>=m)r=n
p=r
while(!0){if(p>s){q=p-1
if(!(q>=0))return A.e(a,q)
q=a[q]===0}else q=!1
if(!q)break;--p}if(s===0){if(p!==s)throw A.d(A.a3("byte stream contains leading data"))}else B.d.u(o,s)
r+=3}return o},
a2:function a2(a){this.b=a},
d1:function d1(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
ak:function ak(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=b
_.c=c
_.d=null
_.e=d
_.f=$
_.r=!1
_.w=e
_.x=0
_.y=f
_.z=g},
d_:function d_(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g},
d0:function d0(a,b,c,d){var _=this
_.a=a
_.b=b
_.c=c
_.d=d},
f9(a,b,c){var s=new A.cs(a,c,b),r=a.f
if(r<=0||r>255)A.W(A.a3("Invalid key ring size"))
s.b=t.bG.a(A.f5(r,null,!1,t.aF))
return s},
d7:function d7(a,b,c,d,e,f,g){var _=this
_.a=a
_.b=b
_.c=c
_.d=d
_.e=e
_.f=f
_.r=g},
cj:function cj(a,b,c,d){var _=this
_.a=a
_.c=b
_.d=c
_.e=null
_.f=d},
aW:function aW(a,b){this.a=a
this.b=b},
cs:function cs(a,b,c){var _=this
_.a=0
_.b=$
_.c=!1
_.d=a
_.e=b
_.f=c
_.r=0},
df:function df(){var _=this
_.a=0
_.b=null
_.d=_.c=0},
h_(a,b,c){var s,r,q=null,p=A.ay($.aP,new A.e5(b),t.j)
if(p==null){$.v().i(B.f,"creating new cryptor for "+a+", trackId "+b,q,q)
s=A.b(v.G.self)
r=t.S
p=new A.ak(A.br(r,r),a,b,c.G(a),B.m,s,new A.df())
B.d.u($.aP,p)}else if(a!==p.b){s=c.G(a)
if(p.w!==B.j){$.v().i(B.f,"setParticipantId: lastError != CryptorError.kOk, reset state to kNew",q,q)
p.w=B.m}p.b=a
p.e=s
p.z.b4()}return p},
fY(a,b,c){var s,r=A.ay($.eR,new A.e0(b),t.D)
if(r==null){$.v().i(B.f,"creating new cryptor for "+a+", dataCryptorId "+b,null,null)
s=A.b(v.G.self)
r=new A.aw(a,b,c.G(a),s)
B.d.u($.eR,r)}else if(a!==r.b){s=c.G(a)
r.b=a
r.d=s}return r},
jt(a){var s=A.ay($.aP,new A.ep(a),t.j)
if(s!=null)s.b=null},
ju(a){var s=A.ay($.eR,new A.eq(a),t.D)
if(s!=null)s.b=null},
eP(){var s=0,r=A.G(t.H),q,p
var $async$eP=A.H(function(a,b){if(a===1)return A.D(b,r)
while(true)switch(s){case 0:p=$.cP()
if(p.b!=null)A.W(A.bG('Please set "hierarchicalLoggingEnabled" to true if you want to change the level on a non-root logger.'))
J.eT(p.c,B.c)
p.c=B.c
p.aQ().bN(new A.eh())
p=$.v()
p.i(B.f,"Worker created",null,null)
q=v.G
if("RTCTransformEvent" in A.b(q.self)){p.i(B.f,"setup RTCTransformEvent event handler",null,null)
A.b(q.self).onrtctransform=A.fG(new A.ei())}A.b(q.self).onmessage=A.fG(new A.ej(new A.ek()))
return A.E(null,r)}})
return A.F($async$eP,r)},
e5:function e5(a){this.a=a},
e0:function e0(a){this.a=a},
ep:function ep(a){this.a=a},
eq:function eq(a){this.a=a},
eh:function eh(){},
ei:function ei(){},
ek:function ek(){},
eb:function eb(a){this.a=a},
ec:function ec(a){this.a=a},
ed:function ed(a){this.a=a},
ee:function ee(a){this.a=a},
ef:function ef(a){this.a=a},
eg:function eg(a){this.a=a},
ej:function ej(a){this.a=a},
jp(a){if(typeof dartPrint=="function"){dartPrint(a)
return}if(typeof console=="object"&&typeof console.log!="undefined"){console.log(a)
return}if(typeof print=="function"){print(a)
return}throw"Unable to print message: "+String(a)},
au(a){throw A.B(A.hy(a),new Error())},
jr(a){throw A.B(new A.bo("Field '"+a+"' has been assigned during initialization."),new Error())},
ay(a,b,c){var s,r,q
for(s=a.length,r=0;r<a.length;a.length===s||(0,A.bd)(a),++r){q=a[r]
if(b.$1(q))return q}return null},
fX(a,b){switch(a){case"HKDF":return A.j(["name","HKDF","salt",b,"hash","SHA-256","info",new Uint8Array(128)],t.N,t.z)
case"PBKDF2":return A.j(["name","PBKDF2","salt",b,"hash","SHA-256","iterations",1e5],t.N,t.z)
default:throw A.d(A.a3("algorithm "+a+" is currently unsupported"))}}},B={}
var w=[A,J,B]
var $={}
A.eA.prototype={}
J.cd.prototype={
F(a,b){return a===b},
gt(a){return A.bB(a)},
k(a){return"Instance of '"+A.cu(a)+"'"},
gq(a){return A.as(A.eJ(this))}}
J.cf.prototype={
k(a){return String(a)},
gt(a){return a?519018:218159},
gq(a){return A.as(t.y)},
$io:1,
$iV:1}
J.bm.prototype={
F(a,b){return null==b},
k(a){return"null"},
gt(a){return 0},
$io:1,
$iy:1}
J.bn.prototype={$iq:1}
J.al.prototype={
gt(a){return 0},
gq(a){return B.W},
k(a){return String(a)}}
J.ct.prototype={}
J.bE.prototype={}
J.a6.prototype={
k(a){var s=a[$.er()]
if(s==null)return this.bb(a)
return"JavaScript function for "+J.T(s)},
$iax:1}
J.aU.prototype={
gt(a){return 0},
k(a){return String(a)}}
J.aV.prototype={
gt(a){return 0},
k(a){return String(a)}}
J.z.prototype={
u(a,b){A.ae(a).c.a(b)
a.$flags&1&&A.X(a,29)
a.push(b)},
bz(a,b){var s
A.ae(a).h("f<1>").a(b)
a.$flags&1&&A.X(a,"addAll",2)
for(s=b.gA(b);s.p();)a.push(s.gn())},
V(a,b,c){var s=A.ae(a)
return new A.a9(a,s.l(c).h("1(2)").a(b),s.h("@<1>").l(c).h("a9<1,2>"))},
T(a,b){if(!(b>=0&&b<a.length))return A.e(a,b)
return a[b]},
k(a){return A.d5(a,"[","]")},
gA(a){return new J.bf(a,a.length,A.ae(a).h("bf<1>"))},
gt(a){return A.bB(a)},
gm(a){return a.length},
j(a,b){A.p(b)
if(!(b>=0&&b<a.length))throw A.d(A.cO(a,b))
return a[b]},
v(a,b,c){A.ae(a).c.a(c)
a.$flags&2&&A.X(a)
if(!(b>=0&&b<a.length))throw A.d(A.cO(a,b))
a[b]=c},
gq(a){return A.as(A.ae(a))},
$il:1,
$if:1,
$ir:1}
J.ce.prototype={
bW(a){var s,r,q
if(!Array.isArray(a))return null
s=a.$flags|0
if((s&4)!==0)r="const, "
else if((s&2)!==0)r="unmodifiable, "
else r=(s&1)!==0?"fixed, ":""
q="Instance of '"+A.cu(a)+"'"
if(r==="")return q
return q+" ("+r+"length: "+a.length+")"}}
J.d6.prototype={}
J.bf.prototype={
gn(){var s=this.d
return s==null?this.$ti.c.a(s):s},
p(){var s,r=this,q=r.a,p=q.length
if(r.b!==p){q=A.bd(q)
throw A.d(q)}s=r.c
if(s>=p){r.d=null
return!1}r.d=q[s]
r.c=s+1
return!0},
$ia4:1}
J.ch.prototype={
bU(a){var s
if(a>=-2147483648&&a<=2147483647)return a|0
if(isFinite(a)){s=a<0?Math.ceil(a):Math.floor(a)
return s+0}throw A.d(A.bG(""+a+".toInt()"))},
bV(a,b){var s,r,q,p,o
if(b<2||b>36)throw A.d(A.aa(b,2,36,"radix",null))
s=a.toString(b)
r=s.length
q=r-1
if(!(q>=0))return A.e(s,q)
if(s.charCodeAt(q)!==41)return s
p=/^([\da-z]+)(?:\.([\da-z]+))?\(e\+(\d+)\)$/.exec(s)
if(p==null)A.W(A.bG("Unexpected toString result: "+s))
r=p.length
if(1>=r)return A.e(p,1)
s=p[1]
if(3>=r)return A.e(p,3)
o=+p[3]
r=p[2]
if(r!=null){s+=r
o-=r.length}return s+B.k.aB("0",o)},
k(a){if(a===0&&1/a<0)return"-0.0"
else return""+a},
gt(a){var s,r,q,p,o=a|0
if(a===o)return o&536870911
s=Math.abs(a)
r=Math.log(s)/0.6931471805599453|0
q=Math.pow(2,r)
p=s<1?s/q:q/s
return((p*9007199254740992|0)+(p*3542243181176521|0))*599197+r*1259&536870911},
a9(a,b){var s=a%b
if(s===0)return 0
if(s>0)return s
return s+b},
bw(a,b){return(a|0)===a?a/b|0:this.bx(a,b)},
bx(a,b){var s=a/b
if(s>=-2147483648&&s<=2147483647)return s|0
if(s>0){if(s!==1/0)return Math.floor(s)}else if(s>-1/0)return Math.ceil(s)
throw A.d(A.bG("Result of truncating division is "+A.c(s)+": "+A.c(a)+" ~/ "+b))},
a3(a,b){var s
if(a>0)s=this.bu(a,b)
else{s=b>31?31:b
s=a>>s>>>0}return s},
bu(a,b){return b>31?0:a>>>b},
gq(a){return A.as(t.o)},
$in:1,
$iaO:1}
J.bl.prototype={
gq(a){return A.as(t.S)},
$io:1,
$ia:1}
J.cg.prototype={
gq(a){return A.as(t.i)},
$io:1}
J.aT.prototype={
bI(a,b){var s=b.length,r=a.length
if(s>r)return!1
return b===this.aF(a,r-s)},
ba(a,b){var s=b.length
if(s>a.length)return!1
return b===a.substring(0,s)},
Y(a,b,c){return a.substring(b,A.fe(b,c,a.length))},
aF(a,b){return this.Y(a,b,null)},
aB(a,b){var s,r
if(0>=b)return""
if(b===1||a.length===0)return a
if(b!==b>>>0)throw A.d(B.K)
for(s=a,r="";!0;){if((b&1)===1)r=s+r
b=b>>>1
if(b===0)break
s+=s}return r},
bL(a,b){var s=a.length,r=b.length
if(s+r>s)s-=r
return a.lastIndexOf(b,s)},
k(a){return a},
gt(a){var s,r,q
for(s=a.length,r=0,q=0;q<s;++q){r=r+a.charCodeAt(q)&536870911
r=r+((r&524287)<<10)&536870911
r^=r>>6}r=r+((r&67108863)<<3)&536870911
r^=r>>11
return r+((r&16383)<<15)&536870911},
gq(a){return A.as(t.N)},
gm(a){return a.length},
j(a,b){A.p(b)
if(!(b.bY(0,0)&&b.bZ(0,a.length)))throw A.d(A.cO(a,b))
return a[b]},
$io:1,
$ifa:1,
$ia5:1}
A.b2.prototype={
u(a,b){var s,r,q,p,o,n,m,l=this
t.L.a(b)
s=b.length
if(s===0)return
r=l.a+s
q=l.b
p=q.length
if(p<r){o=r*2
if(o<1024)o=1024
else{n=o-1
n|=B.i.a3(n,1)
n|=n>>>2
n|=n>>>4
n|=n>>>8
o=((n|n>>>16)>>>0)+1}m=new Uint8Array(o)
B.e.aD(m,0,p,q)
l.b=m
q=m}B.e.aD(q,l.a,r,b)
l.a=r},
az(){var s=this
if(s.a===0)return $.cQ()
return new Uint8Array(A.ar(J.eW(B.e.gH(s.b),s.b.byteOffset,s.a)))},
gm(a){return this.a},
$ihm:1}
A.bo.prototype={
k(a){return"LateInitializationError: "+this.a}}
A.de.prototype={}
A.l.prototype={}
A.a7.prototype={
gA(a){var s=this
return new A.aA(s,s.gm(s),A.K(s).h("aA<a7.E>"))},
V(a,b,c){var s=A.K(this)
return new A.a9(this,s.l(c).h("1(a7.E)").a(b),s.h("@<a7.E>").l(c).h("a9<1,2>"))}}
A.aA.prototype={
gn(){var s=this.d
return s==null?this.$ti.c.a(s):s},
p(){var s,r=this,q=r.a,p=J.e1(q),o=p.gm(q)
if(r.b!==o)throw A.d(A.bh(q))
s=r.c
if(s>=o){r.d=null
return!1}r.d=p.T(q,s);++r.c
return!0},
$ia4:1}
A.a8.prototype={
gA(a){var s=this.a
return new A.bt(s.gA(s),this.b,A.K(this).h("bt<1,2>"))},
gm(a){var s=this.a
return s.gm(s)}}
A.bi.prototype={$il:1}
A.bt.prototype={
p(){var s=this,r=s.b
if(r.p()){s.a=s.c.$1(r.gn())
return!0}s.a=null
return!1},
gn(){var s=this.a
return s==null?this.$ti.y[1].a(s):s},
$ia4:1}
A.a9.prototype={
gm(a){return J.aQ(this.a)},
T(a,b){return this.b.$1(J.hi(this.a,b))}}
A.aE.prototype={
gA(a){return new A.bH(J.ev(this.a),this.b,this.$ti.h("bH<1>"))},
V(a,b,c){var s=this.$ti
return new A.a8(this,s.l(c).h("1(2)").a(b),s.h("@<1>").l(c).h("a8<1,2>"))}}
A.bH.prototype={
p(){var s,r
for(s=this.a,r=this.b;s.p();)if(r.$1(s.gn()))return!0
return!1},
gn(){return this.a.gn()},
$ia4:1}
A.L.prototype={}
A.bC.prototype={}
A.dj.prototype={
C(a){var s,r,q=this,p=new RegExp(q.a).exec(a)
if(p==null)return null
s=Object.create(null)
r=q.b
if(r!==-1)s.arguments=p[r+1]
r=q.c
if(r!==-1)s.argumentsExpr=p[r+1]
r=q.d
if(r!==-1)s.expr=p[r+1]
r=q.e
if(r!==-1)s.method=p[r+1]
r=q.f
if(r!==-1)s.receiver=p[r+1]
return s}}
A.bA.prototype={
k(a){return"Null check operator used on a null value"}}
A.ci.prototype={
k(a){var s,r=this,q="NoSuchMethodError: method not found: '",p=r.b
if(p==null)return"NoSuchMethodError: "+r.a
s=r.c
if(s==null)return q+p+"' ("+r.a+")"
return q+p+"' on '"+s+"' ("+r.a+")"}}
A.cB.prototype={
k(a){var s=this.a
return s.length===0?"Error":"Error: "+s}}
A.dd.prototype={
k(a){return"Throw of null ('"+(this.a===null?"null":"undefined")+"' from JavaScript)"}}
A.bk.prototype={}
A.bU.prototype={
k(a){var s,r=this.b
if(r!=null)return r
r=this.a
s=r!==null&&typeof r==="object"?r.stack:null
return this.b=s==null?"":s},
$ia1:1}
A.aj.prototype={
k(a){var s=this.constructor,r=s==null?null:s.name
return"Closure '"+A.h3(r==null?"unknown":r)+"'"},
$iax:1,
gbX(){return this},
$C:"$1",
$R:1,
$D:null}
A.c6.prototype={$C:"$0",$R:0}
A.c7.prototype={$C:"$2",$R:2}
A.cy.prototype={}
A.cw.prototype={
k(a){var s=this.$static_name
if(s==null)return"Closure of unknown static method"
return"Closure '"+A.h3(s)+"'"}}
A.aR.prototype={
F(a,b){if(b==null)return!1
if(this===b)return!0
if(!(b instanceof A.aR))return!1
return this.$_target===b.$_target&&this.a===b.a},
gt(a){return(A.em(this.a)^A.bB(this.$_target))>>>0},
k(a){return"Closure '"+this.$_name+"' of "+("Instance of '"+A.cu(this.a)+"'")}}
A.cv.prototype={
k(a){return"RuntimeError: "+this.a}}
A.az.prototype={
gm(a){return this.a},
ga8(){return new A.bq(this,this.$ti.h("bq<1>"))},
a5(a){var s=this.b
if(s==null)return!1
return s[a]!=null},
j(a,b){var s,r,q,p,o=null
if(typeof b=="string"){s=this.b
if(s==null)return o
r=s[b]
q=r==null?o:r.b
return q}else if(typeof b=="number"&&(b&0x3fffffff)===b){p=this.c
if(p==null)return o
r=p[b]
q=r==null?o:r.b
return q}else return this.bK(b)},
bK(a){var s,r,q=this.d
if(q==null)return null
s=q[J.cR(a)&1073741823]
r=this.b0(s,a)
if(r<0)return null
return s[r].b},
v(a,b,c){var s,r,q,p,o,n,m=this,l=m.$ti
l.c.a(b)
l.y[1].a(c)
if(typeof b=="string"){s=m.b
m.aG(s==null?m.b=m.ai():s,b,c)}else if(typeof b=="number"&&(b&0x3fffffff)===b){r=m.c
m.aG(r==null?m.c=m.ai():r,b,c)}else{q=m.d
if(q==null)q=m.d=m.ai()
p=J.cR(b)&1073741823
o=q[p]
if(o==null)q[p]=[m.aj(b,c)]
else{n=m.b0(o,b)
if(n>=0)o[n].b=c
else o.push(m.aj(b,c))}}},
bP(a,b){var s,r,q=this,p=q.$ti
p.c.a(a)
p.h("2()").a(b)
if(q.a5(a)){s=q.j(0,a)
return s==null?p.y[1].a(s):s}r=b.$0()
q.v(0,a,r)
return r},
bQ(a,b){var s=this.br(this.b,b)
return s},
aq(a,b){var s,r,q=this
q.$ti.h("~(1,2)").a(b)
s=q.e
r=q.r
for(;s!=null;){b.$2(s.a,s.b)
if(r!==q.r)throw A.d(A.bh(q))
s=s.c}},
aG(a,b,c){var s,r=this.$ti
r.c.a(b)
r.y[1].a(c)
s=a[b]
if(s==null)a[b]=this.aj(b,c)
else s.b=c},
br(a,b){var s
if(a==null)return null
s=a[b]
if(s==null)return null
this.by(s)
delete a[b]
return s.b},
aR(){this.r=this.r+1&1073741823},
aj(a,b){var s=this,r=s.$ti,q=new A.d8(r.c.a(a),r.y[1].a(b))
if(s.e==null)s.e=s.f=q
else{r=s.f
r.toString
q.d=r
s.f=r.c=q}++s.a
s.aR()
return q},
by(a){var s=this,r=a.d,q=a.c
if(r==null)s.e=q
else r.c=q
if(q==null)s.f=r
else q.d=r;--s.a
s.aR()},
b0(a,b){var s,r
if(a==null)return-1
s=a.length
for(r=0;r<s;++r)if(J.eT(a[r].a,b))return r
return-1},
k(a){return A.f7(this)},
ai(){var s=Object.create(null)
s["<non-identifier-key>"]=s
delete s["<non-identifier-key>"]
return s},
$if3:1}
A.d8.prototype={}
A.bq.prototype={
gm(a){return this.a.a},
gA(a){var s=this.a
return new A.bp(s,s.r,s.e,this.$ti.h("bp<1>"))}}
A.bp.prototype={
gn(){return this.d},
p(){var s,r=this,q=r.a
if(r.b!==q.r)throw A.d(A.bh(q))
s=r.c
if(s==null){r.d=null
return!1}else{r.d=s.a
r.c=s.c
return!0}},
$ia4:1}
A.e6.prototype={
$1(a){return this.a(a)},
$S:13}
A.e7.prototype={
$2(a,b){return this.a(a,b)},
$S:14}
A.e8.prototype={
$1(a){return this.a(A.h(a))},
$S:15}
A.an.prototype={
gq(a){return B.P},
a4(a,b,c){return c==null?new Uint8Array(a,b):new Uint8Array(a,b,c)},
aV(a){return this.a4(a,0,null)},
$io:1,
$ian:1,
$ibg:1}
A.aY.prototype={$iaY:1}
A.bx.prototype={
gH(a){if(((a.$flags|0)&2)!==0)return new A.cL(a.buffer)
else return a.buffer},
bo(a,b,c,d){var s=A.aa(b,0,c,d,null)
throw A.d(s)},
aL(a,b,c,d){if(b>>>0!==b||b>c)this.bo(a,b,c,d)}}
A.cL.prototype={
a4(a,b,c){var s=A.I(this.a,b,c)
s.$flags=3
return s},
aV(a){return this.a4(0,0,null)},
$ibg:1}
A.bu.prototype={
gq(a){return B.Q},
bt(a,b,c){return a.setInt8(b,c)},
$io:1,
$iez:1}
A.C.prototype={
gm(a){return a.length},
$iP:1}
A.bv.prototype={
j(a,b){A.p(b)
A.aJ(b,a,a.length)
return a[b]},
$il:1,
$if:1,
$ir:1}
A.bw.prototype={
aD(a,b,c,d){var s,r,q,p
t.e.a(d)
a.$flags&2&&A.X(a,5)
s=a.length
this.aL(a,b,s,"start")
this.aL(a,c,s,"end")
if(b>c)A.W(A.aa(b,0,c,null,null))
r=c-b
q=d.length
if(q<r)A.W(A.dg("Not enough elements"))
p=q!==r?d.subarray(0,r):d
a.set(p,b)
return},
$il:1,
$if:1,
$ir:1}
A.ck.prototype={
gq(a){return B.R},
$io:1,
$icX:1}
A.cl.prototype={
gq(a){return B.S},
$io:1,
$icY:1}
A.cm.prototype={
gq(a){return B.T},
j(a,b){A.p(b)
A.aJ(b,a,a.length)
return a[b]},
$io:1,
$id2:1}
A.cn.prototype={
gq(a){return B.U},
j(a,b){A.p(b)
A.aJ(b,a,a.length)
return a[b]},
$io:1,
$id3:1}
A.co.prototype={
gq(a){return B.V},
j(a,b){A.p(b)
A.aJ(b,a,a.length)
return a[b]},
$io:1,
$id4:1}
A.cp.prototype={
gq(a){return B.Y},
j(a,b){A.p(b)
A.aJ(b,a,a.length)
return a[b]},
$io:1,
$idl:1}
A.cq.prototype={
gq(a){return B.Z},
j(a,b){A.p(b)
A.aJ(b,a,a.length)
return a[b]},
$io:1,
$idm:1}
A.by.prototype={
gq(a){return B.a_},
gm(a){return a.length},
j(a,b){A.p(b)
A.aJ(b,a,a.length)
return a[b]},
$io:1,
$idn:1}
A.bz.prototype={
gq(a){return B.a0},
gm(a){return a.length},
j(a,b){A.p(b)
A.aJ(b,a,a.length)
return a[b]},
B(a,b,c){return new Uint8Array(a.subarray(b,A.ir(b,c,a.length)))},
aE(a,b){return this.B(a,b,null)},
$io:1,
$icz:1}
A.bQ.prototype={}
A.bR.prototype={}
A.bS.prototype={}
A.bT.prototype={}
A.a0.prototype={
h(a){return A.dQ(v.typeUniverse,this,a)},
l(a){return A.ie(v.typeUniverse,this,a)}}
A.cG.prototype={}
A.dO.prototype={
k(a){return A.R(this.a,null)}}
A.cF.prototype={
k(a){return this.a}}
A.bW.prototype={$iab:1}
A.dq.prototype={
$1(a){var s=this.a,r=s.a
s.a=null
r.$0()},
$S:5}
A.dp.prototype={
$1(a){var s,r
this.a.a=t.M.a(a)
s=this.b
r=this.c
s.firstChild?s.removeChild(r):s.appendChild(r)},
$S:16}
A.dr.prototype={
$0(){this.a.$0()},
$S:6}
A.ds.prototype={
$0(){this.a.$0()},
$S:6}
A.dM.prototype={
be(a,b){if(self.setTimeout!=null)self.setTimeout(A.c2(new A.dN(this,b),0),a)
else throw A.d(A.bG("`setTimeout()` not found."))}}
A.dN.prototype={
$0(){this.b.$0()},
$S:0}
A.cC.prototype={
an(a){var s,r=this,q=r.$ti
q.h("1/?").a(a)
if(a==null)a=q.c.a(a)
if(!r.b)r.a.ac(a)
else{s=r.a
if(q.h("a_<1>").b(a))s.aK(a)
else s.aM(a)}},
ao(a,b){var s=this.a
if(this.b)s.a_(new A.O(a,b))
else s.ad(new A.O(a,b))}}
A.dT.prototype={
$1(a){return this.a.$2(0,a)},
$S:3}
A.dU.prototype={
$2(a,b){this.a.$2(1,new A.bk(a,t.l.a(b)))},
$S:17}
A.dX.prototype={
$2(a,b){this.a(A.p(a),b)},
$S:18}
A.O.prototype={
k(a){return A.c(this.a)},
$iw:1,
gO(){return this.b}}
A.b1.prototype={}
A.ao.prototype={
ak(){},
al(){},
sa0(a){this.ch=this.$ti.h("ao<1>?").a(a)},
sam(a){this.CW=this.$ti.h("ao<1>?").a(a)}}
A.aF.prototype={
gah(){return this.c<4},
bv(a,b,c,d){var s,r,q,p,o,n,m=this,l=A.K(m)
l.h("~(1)?").a(a)
t.Y.a(c)
if((m.c&4)!==0){l=new A.b3($.t,l.h("b3<1>"))
A.h2(l.gbp())
if(c!=null)l.c=t.M.a(c)
return l}s=$.t
r=d?1:0
q=b!=null?32:0
t.h.l(l.c).h("1(2)").a(a)
A.i_(s,b)
p=c==null?A.j6():c
t.M.a(p)
l=l.h("ao<1>")
o=new A.ao(m,a,s,r|q,l)
o.CW=o
o.ch=o
l.a(o)
o.ay=m.c&1
n=m.e
m.e=o
o.sa0(null)
o.sam(n)
if(n==null)m.d=o
else n.sa0(o)
if(m.d==m.e)A.fR(m.a)
return o},
aa(){if((this.c&4)!==0)return new A.aD("Cannot add new events after calling close")
return new A.aD("Cannot add new events while doing an addStream")},
bm(a){var s,r,q,p,o,n=this,m=A.K(n)
m.h("~(ad<1>)").a(a)
s=n.c
if((s&2)!==0)throw A.d(A.dg(u.o))
r=n.d
if(r==null)return
q=s&1
n.c=s^3
for(m=m.h("ao<1>");r!=null;){s=r.ay
if((s&1)===q){r.ay=s|2
a.$1(r)
s=r.ay^=1
p=r.ch
if((s&4)!==0){m.a(r)
o=r.CW
if(o==null)n.d=p
else o.sa0(p)
if(p==null)n.e=o
else p.sam(o)
r.sam(r)
r.sa0(r)}r.ay&=4294967293
r=p}else r=r.ch}n.c&=4294967293
if(n.d==null)n.aJ()},
aJ(){if((this.c&4)!==0)if(null.gc_())null.ac(null)
A.fR(this.b)},
$ifh:1,
$ifv:1,
$iap:1}
A.bV.prototype={
gah(){return A.aF.prototype.gah.call(this)&&(this.c&2)===0},
aa(){if((this.c&2)!==0)return new A.aD(u.o)
return this.bc()},
a2(a){var s,r=this
r.$ti.c.a(a)
s=r.d
if(s==null)return
if(s===r.e){r.c|=2
s.aH(a)
r.c&=4294967293
if(r.d==null)r.aJ()
return}r.bm(new A.dL(r,a))}}
A.dL.prototype={
$1(a){this.a.$ti.h("ad<1>").a(a).aH(this.b)},
$S(){return this.a.$ti.h("~(ad<1>)")}}
A.cE.prototype={
ao(a,b){var s=this.a
if((s.a&30)!==0)throw A.d(A.dg("Future already completed"))
s.ad(A.iB(a,b))},
aX(a){return this.ao(a,null)}}
A.bI.prototype={
an(a){var s,r=this.$ti
r.h("1/?").a(a)
s=this.a
if((s.a&30)!==0)throw A.d(A.dg("Future already completed"))
s.ac(r.h("1/").a(a))}}
A.aG.prototype={
bO(a){if((this.c&15)!==6)return!0
return this.b.b.aw(t.c1.a(this.d),a.a,t.y,t.K)},
bJ(a){var s,r=this,q=r.e,p=null,o=t.z,n=t.K,m=a.a,l=r.b.b
if(t.Q.b(q))p=l.bS(q,m,a.b,o,n,t.l)
else p=l.aw(t.v.a(q),m,o,n)
try{o=r.$ti.h("2/").a(p)
return o}catch(s){if(t.b7.b(A.M(s))){if((r.c&1)!==0)throw A.d(A.ai("The error handler of Future.then must return a value of the returned future's type","onError"))
throw A.d(A.ai("The error handler of Future.catchError must return a value of the future's type","onError"))}else throw s}}}
A.x.prototype={
b6(a,b,c){var s,r,q=this.$ti
q.l(c).h("1/(2)").a(a)
s=$.t
if(s===B.h){if(!t.Q.b(b)&&!t.v.b(b))throw A.d(A.ex(b,"onError",u.c))}else{c.h("@<0/>").l(q.c).h("1(2)").a(a)
b=A.iS(b,s)}r=new A.x(s,c.h("x<0>"))
this.ab(new A.aG(r,3,a,b,q.h("@<1>").l(c).h("aG<1,2>")))
return r},
aU(a,b,c){var s,r=this.$ti
r.l(c).h("1/(2)").a(a)
s=new A.x($.t,c.h("x<0>"))
this.ab(new A.aG(s,19,a,b,r.h("@<1>").l(c).h("aG<1,2>")))
return s},
bs(a){this.a=this.a&1|16
this.c=a},
Z(a){this.a=a.a&30|this.a&1
this.c=a.c},
ab(a){var s,r=this,q=r.a
if(q<=3){a.a=t.F.a(r.c)
r.c=a}else{if((q&4)!==0){s=t._.a(r.c)
if((s.a&24)===0){s.ab(a)
return}r.Z(s)}A.b7(null,null,r.b,t.M.a(new A.dx(r,a)))}},
aS(a){var s,r,q,p,o,n,m=this,l={}
l.a=a
if(a==null)return
s=m.a
if(s<=3){r=t.F.a(m.c)
m.c=a
if(r!=null){q=a.a
for(p=a;q!=null;p=q,q=o)o=q.a
p.a=r}}else{if((s&4)!==0){n=t._.a(m.c)
if((n.a&24)===0){n.aS(a)
return}m.Z(n)}l.a=m.a1(a)
A.b7(null,null,m.b,t.M.a(new A.dB(l,m)))}},
P(){var s=t.F.a(this.c)
this.c=null
return this.a1(s)},
a1(a){var s,r,q
for(s=a,r=null;s!=null;r=s,s=q){q=s.a
s.a=r}return r},
aM(a){var s,r=this
r.$ti.c.a(a)
s=r.P()
r.a=8
r.c=a
A.aH(r,s)},
bk(a){var s,r,q=this
if((a.a&16)!==0){s=q.b===a.b
s=!(s||s)}else s=!1
if(s)return
r=q.P()
q.Z(a)
A.aH(q,r)},
a_(a){var s=this.P()
this.bs(a)
A.aH(this,s)},
bj(a,b){A.J(a)
t.l.a(b)
this.a_(new A.O(a,b))},
ac(a){var s=this.$ti
s.h("1/").a(a)
if(s.h("a_<1>").b(a)){this.aK(a)
return}this.bg(a)},
bg(a){var s=this
s.$ti.c.a(a)
s.a^=2
A.b7(null,null,s.b,t.M.a(new A.dz(s,a)))},
aK(a){A.eD(this.$ti.h("a_<1>").a(a),this,!1)
return},
ad(a){this.a^=2
A.b7(null,null,this.b,t.M.a(new A.dy(this,a)))},
$ia_:1}
A.dx.prototype={
$0(){A.aH(this.a,this.b)},
$S:0}
A.dB.prototype={
$0(){A.aH(this.b,this.a.a)},
$S:0}
A.dA.prototype={
$0(){A.eD(this.a.a,this.b,!0)},
$S:0}
A.dz.prototype={
$0(){this.a.aM(this.b)},
$S:0}
A.dy.prototype={
$0(){this.a.a_(this.b)},
$S:0}
A.dE.prototype={
$0(){var s,r,q,p,o,n,m,l,k=this,j=null
try{q=k.a.a
j=q.b.b.bR(t.bd.a(q.d),t.z)}catch(p){s=A.M(p)
r=A.aM(p)
if(k.c&&t.n.a(k.b.a.c).a===s){q=k.a
q.c=t.n.a(k.b.a.c)}else{q=s
o=r
if(o==null)o=A.ey(q)
n=k.a
n.c=new A.O(q,o)
q=n}q.b=!0
return}if(j instanceof A.x&&(j.a&24)!==0){if((j.a&16)!==0){q=k.a
q.c=t.n.a(j.c)
q.b=!0}return}if(j instanceof A.x){m=k.b.a
l=new A.x(m.b,m.$ti)
j.b6(new A.dF(l,m),new A.dG(l),t.H)
q=k.a
q.c=l
q.b=!1}},
$S:0}
A.dF.prototype={
$1(a){this.a.bk(this.b)},
$S:5}
A.dG.prototype={
$2(a,b){A.J(a)
t.l.a(b)
this.a.a_(new A.O(a,b))},
$S:19}
A.dD.prototype={
$0(){var s,r,q,p,o,n,m,l
try{q=this.a
p=q.a
o=p.$ti
n=o.c
m=n.a(this.b)
q.c=p.b.b.aw(o.h("2/(1)").a(p.d),m,o.h("2/"),n)}catch(l){s=A.M(l)
r=A.aM(l)
q=s
p=r
if(p==null)p=A.ey(q)
o=this.a
o.c=new A.O(q,p)
o.b=!0}},
$S:0}
A.dC.prototype={
$0(){var s,r,q,p,o,n,m,l=this
try{s=t.n.a(l.a.a.c)
p=l.b
if(p.a.bO(s)&&p.a.e!=null){p.c=p.a.bJ(s)
p.b=!1}}catch(o){r=A.M(o)
q=A.aM(o)
p=t.n.a(l.a.a.c)
if(p.a===r){n=l.b
n.c=p
p=n}else{p=r
n=q
if(n==null)n=A.ey(p)
m=l.b
m.c=new A.O(p,n)
p=m}p.b=!0}},
$S:0}
A.cD.prototype={}
A.b_.prototype={
gm(a){var s={},r=new A.x($.t,t.aQ)
s.a=0
this.b1(new A.dh(s,this),!0,new A.di(s,r),r.gbi())
return r}}
A.dh.prototype={
$1(a){this.b.$ti.c.a(a);++this.a.a},
$S(){return this.b.$ti.h("~(1)")}}
A.di.prototype={
$0(){var s=this.b,r=s.$ti,q=r.h("1/").a(this.a.a),p=s.P()
r.c.a(q)
s.a=8
s.c=q
A.aH(s,p)},
$S:0}
A.bJ.prototype={
gt(a){return(A.bB(this.a)^892482866)>>>0},
F(a,b){if(b==null)return!1
if(this===b)return!0
return b instanceof A.b1&&b.a===this.a}}
A.bK.prototype={
ak(){A.K(this.w).h("b0<1>").a(this)},
al(){A.K(this.w).h("b0<1>").a(this)}}
A.ad.prototype={
aH(a){var s,r=this,q=A.K(r)
q.c.a(a)
s=r.e
if((s&8)!==0)return
if(s<64)r.a2(a)
else r.bf(new A.bL(a,q.h("bL<1>")))},
ak(){},
al(){},
bf(a){var s,r,q=this,p=q.r
if(p==null)p=q.r=new A.cH(A.K(q).h("cH<1>"))
s=p.c
if(s==null)p.b=p.c=a
else p.c=s.a=a
r=q.e
if((r&128)===0){r|=128
q.e=r
if(r<256)p.aC(q)}},
a2(a){var s,r=this,q=A.K(r).c
q.a(a)
s=r.e
r.e=s|64
r.d.bT(r.a,a,q)
r.e&=4294967231
r.bh((s&4)!==0)},
bh(a){var s,r,q=this,p=q.e
if((p&128)!==0&&q.r.c==null){p=q.e=p&4294967167
s=!1
if((p&4)!==0)if(p<256){s=q.r
s=s==null?null:s.c==null
s=s!==!1}if(s){p&=4294967291
q.e=p}}for(;!0;a=r){if((p&8)!==0){q.r=null
return}r=(p&4)!==0
if(a===r)break
q.e=p^64
if(r)q.ak()
else q.al()
p=q.e&=4294967231}if((p&128)!==0&&p<256)q.r.aC(q)},
$ib0:1,
$iap:1}
A.b5.prototype={
b1(a,b,c,d){var s=this.$ti
s.h("~(1)?").a(a)
t.Y.a(c)
return this.a.bv(s.h("~(1)?").a(a),d,c,b===!0)},
bN(a){return this.b1(a,null,null,null)}}
A.bM.prototype={}
A.bL.prototype={}
A.cH.prototype={
aC(a){var s,r=this
r.$ti.h("ap<1>").a(a)
s=r.a
if(s===1)return
if(s>=1){r.a=1
return}A.h2(new A.dJ(r,a))
r.a=1}}
A.dJ.prototype={
$0(){var s,r,q,p=this.a,o=p.a
p.a=0
if(o===3)return
s=p.$ti.h("ap<1>").a(this.b)
r=p.b
q=r.a
p.b=q
if(q==null)p.c=null
A.K(r).h("ap<1>").a(s).a2(r.b)},
$S:0}
A.b3.prototype={
bq(){var s,r=this,q=r.a-1
if(q===0){r.a=-1
s=r.c
if(s!=null){r.c=null
r.b.b5(s)}}else r.a=q},
$ib0:1}
A.cJ.prototype={}
A.c_.prototype={$ifm:1}
A.dW.prototype={
$0(){A.hu(this.a,this.b)},
$S:0}
A.cI.prototype={
b5(a){var s,r,q
t.M.a(a)
try{if(B.h===$.t){a.$0()
return}A.fO(null,null,this,a,t.H)}catch(q){s=A.M(q)
r=A.aM(q)
A.cN(A.J(s),t.l.a(r))}},
bT(a,b,c){var s,r,q
c.h("~(0)").a(a)
c.a(b)
try{if(B.h===$.t){a.$1(b)
return}A.fP(null,null,this,a,b,t.H,c)}catch(q){s=A.M(q)
r=A.aM(q)
A.cN(A.J(s),t.l.a(r))}},
aW(a){return new A.dK(this,t.M.a(a))},
j(a,b){return null},
bR(a,b){b.h("0()").a(a)
if($.t===B.h)return a.$0()
return A.fO(null,null,this,a,b)},
aw(a,b,c,d){c.h("@<0>").l(d).h("1(2)").a(a)
d.a(b)
if($.t===B.h)return a.$1(b)
return A.fP(null,null,this,a,b,c,d)},
bS(a,b,c,d,e,f){d.h("@<0>").l(e).l(f).h("1(2,3)").a(a)
e.a(b)
f.a(c)
if($.t===B.h)return a.$2(b,c)
return A.iT(null,null,this,a,b,c,d,e,f)},
av(a,b,c,d){return b.h("@<0>").l(c).l(d).h("1(2,3)").a(a)}}
A.dK.prototype={
$0(){return this.a.b5(this.b)},
$S:0}
A.bN.prototype={
gm(a){return this.a},
ga8(){return new A.bO(this,this.$ti.h("bO<1>"))},
a5(a){var s,r
if(typeof a=="string"&&a!=="__proto__"){s=this.b
return s==null?!1:s[a]!=null}else if(typeof a=="number"&&(a&1073741823)===a){r=this.c
return r==null?!1:r[a]!=null}else return this.bl(a)},
bl(a){var s=this.d
if(s==null)return!1
return this.ag(this.aP(s,a),a)>=0},
j(a,b){var s,r,q
if(typeof b=="string"&&b!=="__proto__"){s=this.b
r=s==null?null:A.fp(s,b)
return r}else if(typeof b=="number"&&(b&1073741823)===b){q=this.c
r=q==null?null:A.fp(q,b)
return r}else return this.bn(b)},
bn(a){var s,r,q=this.d
if(q==null)return null
s=this.aP(q,a)
r=this.ag(s,a)
return r<0?null:s[r+1]},
v(a,b,c){var s,r,q,p,o,n,m=this,l=m.$ti
l.c.a(b)
l.y[1].a(c)
if(typeof b=="string"&&b!=="__proto__"){s=m.b
m.aI(s==null?m.b=A.eE():s,b,c)}else if(typeof b=="number"&&(b&1073741823)===b){r=m.c
m.aI(r==null?m.c=A.eE():r,b,c)}else{q=m.d
if(q==null)q=m.d=A.eE()
p=A.em(b)&1073741823
o=q[p]
if(o==null){A.eF(q,p,[b,c]);++m.a
m.e=null}else{n=m.ag(o,b)
if(n>=0)o[n+1]=c
else{o.push(b,c);++m.a
m.e=null}}}},
aq(a,b){var s,r,q,p,o,n,m=this,l=m.$ti
l.h("~(1,2)").a(b)
s=m.aN()
for(r=s.length,q=l.c,l=l.y[1],p=0;p<r;++p){o=s[p]
q.a(o)
n=m.j(0,o)
b.$2(o,n==null?l.a(n):n)
if(s!==m.e)throw A.d(A.bh(m))}},
aN(){var s,r,q,p,o,n,m,l,k,j,i=this,h=i.e
if(h!=null)return h
h=A.f5(i.a,null,!1,t.z)
s=i.b
r=0
if(s!=null){q=Object.getOwnPropertyNames(s)
p=q.length
for(o=0;o<p;++o){h[r]=q[o];++r}}n=i.c
if(n!=null){q=Object.getOwnPropertyNames(n)
p=q.length
for(o=0;o<p;++o){h[r]=+q[o];++r}}m=i.d
if(m!=null){q=Object.getOwnPropertyNames(m)
p=q.length
for(o=0;o<p;++o){l=m[q[o]]
k=l.length
for(j=0;j<k;j+=2){h[r]=l[j];++r}}}return i.e=h},
aI(a,b,c){var s=this.$ti
s.c.a(b)
s.y[1].a(c)
if(a[b]==null){++this.a
this.e=null}A.eF(a,b,c)},
aP(a,b){return a[A.em(b)&1073741823]}}
A.b4.prototype={
ag(a,b){var s,r,q
if(a==null)return-1
s=a.length
for(r=0;r<s;r+=2){q=a[r]
if(q==null?b==null:q===b)return r}return-1}}
A.bO.prototype={
gm(a){return this.a.a},
gA(a){var s=this.a
return new A.bP(s,s.aN(),this.$ti.h("bP<1>"))}}
A.bP.prototype={
gn(){var s=this.d
return s==null?this.$ti.c.a(s):s},
p(){var s=this,r=s.b,q=s.c,p=s.a
if(r!==p.e)throw A.d(A.bh(p))
else if(q>=r.length){s.d=null
return!1}else{s.d=r[q]
s.c=q+1
return!0}},
$ia4:1}
A.u.prototype={
gA(a){return new A.aA(a,a.length,A.bb(a).h("aA<u.E>"))},
T(a,b){if(!(b>=0&&b<a.length))return A.e(a,b)
return a[b]},
V(a,b,c){var s=A.bb(a)
return new A.a9(a,s.l(c).h("1(u.E)").a(b),s.h("@<u.E>").l(c).h("a9<1,2>"))},
k(a){return A.d5(a,"[","]")}}
A.aC.prototype={
aq(a,b){var s,r,q,p=A.K(this)
p.h("~(1,2)").a(b)
for(s=this.ga8(),s=s.gA(s),p=p.y[1];s.p();){r=s.gn()
q=this.j(0,r)
b.$2(r,q==null?p.a(q):q)}},
gm(a){var s=this.ga8()
return s.gm(s)},
k(a){return A.f7(this)},
$ibs:1}
A.db.prototype={
$2(a,b){var s,r=this.a
if(!r.a)this.b.a+=", "
r.a=!1
r=this.b
s=A.c(a)
r.a=(r.a+=s)+": "
s=A.c(b)
r.a+=s},
$S:20}
A.c5.prototype={}
A.cT.prototype={
I(a){var s
t.L.a(a)
s=a.length
if(s===0)return""
s=new A.du("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/").bE(a,0,s,!0)
s.toString
return A.hP(s)}}
A.du.prototype={
bE(a,b,c,d){var s,r,q,p,o
t.L.a(a)
s=this.a
r=(s&3)+(c-b)
q=B.i.bw(r,3)
p=q*4
if(r-q*3>0)p+=4
o=new Uint8Array(p)
this.a=A.hZ(this.b,a,b,c,!0,o,0,s)
if(p>0)return o
return null}}
A.cS.prototype={
I(a){var s,r,q,p=A.fe(0,null,a.length)
if(0===p)return new Uint8Array(0)
s=new A.dt()
r=s.bA(a,0,p)
r.toString
q=s.a
if(q<-1)A.W(A.aS("Missing padding character",a,p))
if(q>0)A.W(A.aS("Invalid length, must be multiple of four",a,p))
s.a=-1
return r}}
A.dt.prototype={
bA(a,b,c){var s,r=this,q=r.a
if(q<0){r.a=A.fn(a,b,c,q)
return null}if(b===c)return new Uint8Array(0)
s=A.hW(a,b,c,q)
r.a=A.hY(a,b,c,s,0,r.a)
return s}}
A.av.prototype={}
A.c9.prototype={}
A.ca.prototype={
F(a,b){if(b==null)return!1
return b instanceof A.ca&&this.a===b.a&&this.b===b.b&&this.c===b.c},
gt(a){return A.hC(this.a,this.b)},
k(a){var s=this,r=A.hs(A.hK(s)),q=A.cb(A.hI(s)),p=A.cb(A.hE(s)),o=A.cb(A.hF(s)),n=A.cb(A.hH(s)),m=A.cb(A.hJ(s)),l=A.f1(A.hG(s)),k=s.b,j=k===0?"":A.f1(k)
k=r+"-"+q
if(s.c)return k+"-"+p+" "+o+":"+n+":"+m+"."+l+j+"Z"
else return k+"-"+p+" "+o+":"+n+":"+m+"."+l+j}}
A.dv.prototype={
k(a){return this.aO()}}
A.w.prototype={
gO(){return A.hD(this)}}
A.c3.prototype={
k(a){var s=this.a
if(s!=null)return"Assertion failed: "+A.cW(s)
return"Assertion failed"}}
A.ab.prototype={}
A.Z.prototype={
gaf(){return"Invalid argument"+(!this.a?"(s)":"")},
gae(){return""},
k(a){var s=this,r=s.c,q=r==null?"":" ("+r+")",p=s.d,o=p==null?"":": "+A.c(p),n=s.gaf()+q+o
if(!s.a)return n
return n+s.gae()+": "+A.cW(s.gar())},
gar(){return this.b}}
A.aZ.prototype={
gar(){return A.fD(this.b)},
gaf(){return"RangeError"},
gae(){var s,r=this.e,q=this.f
if(r==null)s=q!=null?": Not less than or equal to "+A.c(q):""
else if(q==null)s=": Not greater than or equal to "+A.c(r)
else if(q>r)s=": Not in inclusive range "+A.c(r)+".."+A.c(q)
else s=q<r?": Valid value range is empty":": Only valid value is "+A.c(r)
return s}}
A.cc.prototype={
gar(){return A.p(this.b)},
gaf(){return"RangeError"},
gae(){if(A.p(this.b)<0)return": index must not be negative"
var s=this.f
if(s===0)return": no indices are valid"
return": index should be less than "+s},
gm(a){return this.f}}
A.bF.prototype={
k(a){return"Unsupported operation: "+this.a}}
A.cA.prototype={
k(a){return"UnimplementedError: "+this.a}}
A.aD.prototype={
k(a){return"Bad state: "+this.a}}
A.c8.prototype={
k(a){var s=this.a
if(s==null)return"Concurrent modification during iteration."
return"Concurrent modification during iteration: "+A.cW(s)+"."}}
A.cr.prototype={
k(a){return"Out of Memory"},
gO(){return null},
$iw:1}
A.bD.prototype={
k(a){return"Stack Overflow"},
gO(){return null},
$iw:1}
A.dw.prototype={
k(a){return"Exception: "+this.a}}
A.cZ.prototype={
k(a){var s,r,q,p,o,n,m,l,k,j,i=this.a,h=""!==i?"FormatException: "+i:"FormatException",g=this.c,f=this.b,e=g<0||g>f.length
if(e)g=null
if(g==null){if(f.length>78)f=B.k.Y(f,0,75)+"..."
return h+"\n"+f}for(s=f.length,r=1,q=0,p=!1,o=0;o<g;++o){if(!(o<s))return A.e(f,o)
n=f.charCodeAt(o)
if(n===10){if(q!==o||!p)++r
q=o+1
p=!1}else if(n===13){++r
q=o+1
p=!0}}h=r>1?h+(" (at line "+r+", character "+(g-q+1)+")\n"):h+(" (at character "+(g+1)+")\n")
for(o=g;o<s;++o){if(!(o>=0))return A.e(f,o)
n=f.charCodeAt(o)
if(n===10||n===13){s=o
break}}m=""
if(s-q>78){l="..."
if(g-q<75){k=q+75
j=q}else{if(s-g<75){j=s-75
k=s
l=""}else{j=g-36
k=g+36}m="..."}}else{k=s
j=q
l=""}return h+m+B.k.Y(f,j,k)+l+"\n"+B.k.aB(" ",g-j+m.length)+"^\n"}}
A.f.prototype={
V(a,b,c){var s=A.K(this)
return A.hA(this,s.l(c).h("1(f.E)").a(b),s.h("f.E"),c)},
gm(a){var s,r=this.gA(this)
for(s=0;r.p();)++s
return s},
T(a,b){var s,r
A.fd(b,"index")
s=this.gA(this)
for(r=b;s.p();){if(r===0)return s.gn();--r}throw A.d(A.f2(b,b-r,this,"index"))},
k(a){return A.hv(this,"(",")")}}
A.y.prototype={
gt(a){return A.k.prototype.gt.call(this,0)},
k(a){return"null"}}
A.k.prototype={$ik:1,
F(a,b){return this===b},
gt(a){return A.bB(this)},
k(a){return"Instance of '"+A.cu(this)+"'"},
gq(a){return A.je(this)},
toString(){return this.k(this)}}
A.cK.prototype={
k(a){return""},
$ia1:1}
A.cx.prototype={
gm(a){return this.a.length},
k(a){var s=this.a
return s.charCodeAt(0)==0?s:s}}
A.ea.prototype={
$1(a){var s,r,q,p
if(A.fN(a))return a
s=this.a
if(s.a5(a))return s.j(0,a)
if(t.f.b(a)){r={}
s.v(0,a,r)
for(s=a.ga8(),s=s.gA(s);s.p();){q=s.gn()
r[q]=this.$1(a.j(0,q))}return r}else if(t.R.b(a)){p=[]
s.v(0,a,p)
B.d.bz(p,J.hj(a,this,t.z))
return p}else return a},
$S:8}
A.en.prototype={
$1(a){return this.a.an(this.b.h("0/?").a(a))},
$S:3}
A.eo.prototype={
$1(a){if(a==null)return this.a.aX(new A.dc(a===undefined))
return this.a.aX(a)},
$S:3}
A.dZ.prototype={
$1(a){var s,r,q,p,o,n,m,l,k,j,i,h,g
if(A.fM(a))return a
s=this.a
a.toString
if(s.a5(a))return s.j(0,a)
if(a instanceof Date){r=a.getTime()
if(r<-864e13||r>864e13)A.W(A.aa(r,-864e13,864e13,"millisecondsSinceEpoch",null))
A.dY(!0,"isUtc",t.y)
return new A.ca(r,0,!0)}if(a instanceof RegExp)throw A.d(A.ai("structured clone of RegExp",null))
if(typeof Promise!="undefined"&&a instanceof Promise)return A.ag(a,t.X)
q=Object.getPrototypeOf(a)
if(q===Object.prototype||q===null){p=t.X
o=A.br(p,p)
s.v(0,a,o)
n=Object.keys(a)
m=[]
for(s=n.length,l=0;l<n.length;n.length===s||(0,A.bd)(n),++l)m.push(A.fW(n[l]))
for(k=0;k<n.length;++k){j=n[k]
if(!(k<m.length))return A.e(m,k)
i=m[k]
if(j!=null)o.v(0,i,this.$1(a[j]))}return o}if(a instanceof Array){h=a
o=[]
s.v(0,a,o)
g=A.p(a.length)
for(k=0;k<g;++k){if(!(k<h.length))return A.e(h,k)
o.push(this.$1(h[k]))}return o}return a},
$S:8}
A.dc.prototype={
k(a){return"Promise was rejected with a value of `"+(this.a?"undefined":"null")+"`."}}
A.dH.prototype={
bd(){var s=self.crypto
if(s!=null)if(s.getRandomValues!=null)return
throw A.d(A.bG("No source of cryptographically secure random numbers available."))},
au(a){var s,r,q,p,o,n,m,l,k=null
if(a<=0||a>4294967296)throw A.d(new A.aZ(k,k,!1,k,k,"max must be in range 0 < max \u2264 2^32, was "+a))
if(a>255)if(a>65535)s=a>16777215?4:3
else s=2
else s=1
r=this.a
r.$flags&2&&A.X(r,11)
r.setUint32(0,0,!1)
q=4-s
p=A.p(Math.pow(256,s))
for(o=a-1,n=(a&o)>>>0===0;!0;){crypto.getRandomValues(J.eW(B.r.gH(r),q,s))
m=r.getUint32(0,!1)
if(n)return(m&o)>>>0
l=m%a
if(m-l+a<p)return l}}}
A.am.prototype={
F(a,b){if(b==null)return!1
return b instanceof A.am&&this.b===b.b},
gt(a){return this.b},
k(a){return this.a}}
A.aB.prototype={
k(a){return"["+this.a.a+"] "+this.d+": "+this.b}}
A.aX.prototype={
gb_(){var s=this.b,r=s==null?null:s.a.length!==0,q=this.a
return r===!0?s.gb_()+"."+q:q},
gbM(){var s,r
if(this.b==null){s=this.c
s.toString
r=s}else{s=$.cP().c
s.toString
r=s}return r},
i(a,b,c,d){var s,r=this,q=a.b
if(q>=r.gbM().b){if(q>=2000){A.fg()
a.k(0)}q=r.gb_()
Date.now()
$.f6=$.f6+1
s=new A.aB(a,b,q)
if(r.b==null)r.aT(s)
else $.cP().aT(s)}},
aQ(){if(this.b==null){var s=this.f
if(s==null)s=this.f=new A.bV(null,null,t.W)
return new A.b1(s,A.K(s).h("b1<1>"))}else return $.cP().aQ()},
aT(a){var s=this.f
if(s!=null){A.K(s).c.a(a)
if(!s.gah())A.W(s.aa())
s.a2(a)}return null}}
A.da.prototype={
$0(){var s,r,q,p=this.a
if(B.k.ba(p,"."))A.W(A.ai("name shouldn't start with a '.'",null))
if(B.k.bI(p,"."))A.W(A.ai("name shouldn't end with a '.'",null))
s=B.k.bL(p,".")
if(s===-1)r=p!==""?A.d9(""):null
else{r=A.d9(B.k.Y(p,0,s))
p=B.k.aF(p,s+1)}q=new A.aX(p,r,A.br(t.N,t.I))
if(r==null)q.c=B.f
else r.d.v(0,p,q)
return q},
$S:21}
A.ah.prototype={
aO(){return"Algorithm."+this.b}}
A.bj.prototype={}
A.aw.prototype={
a7(a,b){return this.bH(a,b)},
bH(a1,a2){var s=0,r=A.G(t.a5),q,p=2,o=[],n=this,m,l,k,j,i,h,g,f,e,d,c,b,a,a0
var $async$a7=A.H(function(a3,a4){if(a3===1){o.push(a4)
s=p}while(true)switch(s){case 0:c=$.v()
b=""+a2.length
c.i(B.l,"encodeFunction: buffer "+b,null,null)
h=n.d.K(0)
m=h==null?null:h.b
l=0
if(m==null){c.i(B.c,"encodeFunction: no secretKey for index "+A.c(l)+", cannot encrypt",null,null)
q=null
s=1
break}h=Date.now()
g=new DataView(new ArrayBuffer(12))
f=n.a
if(f===-1)f=n.a=$.es().au(65535)
g.setUint32(0,($.es().au(Math.max(0,4294967295))&-1)>>>0,!1)
g.setUint32(4,h,!1)
g.setUint32(8,h-B.i.a9(f,65535),!1)
n.a=f+1
k=J.et(B.r.gH(g))
e=new DataView(new ArrayBuffer(2))
e.setInt8(0,12)
e.setInt8(1,A.p(l))
p=4
h=A.b(A.b(n.f.crypto).subtle)
f=A.i(A.j(["name","AES-GCM","iv",k],t.N,t.K))
if(f==null)f=A.J(f)
a0=t.a
s=7
return A.m(A.ag(A.b(h.encrypt(f,m,a2)),t.X),$async$a7)
case 7:j=a0.a(a4)
c.i(B.b,"encodeFunction: encrypted buffer: "+b+", cipherText: "+A.I(j,0,null).length,null,null)
b=A.I(j,0,null)
q=new A.bj(b,l,k)
s=1
break
p=2
s=6
break
case 4:p=3
a=o.pop()
i=A.M(a)
$.v().i(B.c,"encodeFunction encrypt: e "+J.T(i),null,null)
throw a
s=6
break
case 3:s=2
break
case 6:case 1:return A.E(q,r)
case 2:return A.D(o.at(-1),r)}})
return A.F($async$a7,r)},
S(a,b){return this.bD(a,b)},
bD(a4,a5){var s=0,r=A.G(t.E),q,p=2,o=[],n=this,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3
var $async$S=A.H(function(a6,a7){if(a6===1){o.push(a7)
s=p}while(true)switch(s){case 0:a1={}
a1.a=0
e=$.v()
d=a5.a
e.i(B.l,"decodeFunction: data packet lenght "+d.length,null,null)
a1.b=a1.c=null
m=0
p=4
c={}
b=a5.c
l=b.length
k=a5.b
j=b
i=d
a=a1.b=n.d.K(m)
e.i(B.b,"decodeFunction: start decrypting data packet length "+J.aQ(i)+", ivLength "+A.c(l)+", keyIndex "+A.c(k)+", iv "+A.c(j),null,null)
if(a==null||!n.d.c){q=null
s=1
break}c.a=a
h=new A.cU(a1,c,n,j,i,m)
g=new A.cV(a1,c,n,h)
p=8
s=11
return A.m(h.$0(),$async$S)
case 11:p=4
s=10
break
case 8:p=7
a2=o.pop()
f=A.M(a2)
e=$.v()
e.i(B.b,"decodeFunction: kInternalError catch "+A.c(f),null,null)
s=12
return A.m(g.$0(),$async$S)
case 12:s=10
break
case 7:s=4
break
case 10:d=a1.c
if(d==null){a1=A.a3(u.r)
throw A.d(a1)}c=n.d
c.r=0
c.c=!0
e.i(B.b,u.f+J.aQ(i)+", decrypted: "+A.I(d,0,null).length,null,null)
a1=a1.c
a1.toString
a1=A.I(a1,0,null)
q=a1
s=1
break
p=2
s=6
break
case 4:p=3
a3=o.pop()
n.d.aY()
throw a3
s=6
break
case 3:s=2
break
case 6:case 1:return A.E(q,r)
case 2:return A.D(o.at(-1),r)}})
return A.F($async$S,r)}}
A.cU.prototype={
$0(){var s=0,r=A.G(t.H),q=this,p,o,n,m,l,k,j
var $async$$0=A.H(function(a,b){if(a===1)return A.D(b,r)
while(true)switch(s){case 0:m=q.c
l=A.b(A.b(m.f.crypto).subtle)
k=A.i(A.j(["name","AES-GCM","iv",q.d],t.N,t.K))
if(k==null)k=A.J(k)
p=q.b
j=t.a
s=2
return A.m(A.ag(A.b(l.decrypt(k,p.a.b,q.e)),t.X),$async$$0)
case 2:o=j.a(b)
k=q.a
k.c=o
l=$.v()
l.i(B.b,u.D+A.I(o,0,null).length,null,null)
n=k.c
if(n==null)throw A.d(A.a3("[decryptFrameInternal] could not decrypt"))
l.i(B.b,u.D+A.I(n,0,null).length,null,null)
s=p.a!==k.b?3:4
break
case 3:l.i(B.l,u.E,null,null)
s=5
return A.m(m.d.L(p.a,q.f),$async$$0)
case 5:case 4:return A.E(null,r)}})
return A.F($async$$0,r)},
$S:2}
A.cV.prototype={
$0(){var s=0,r=A.G(t.H),q=this,p,o,n,m,l,k,j,i,h
var $async$$0=A.H(function(a,b){if(a===1)return A.D(b,r)
while(true)switch(s){case 0:n=q.a
m=n.a
l=q.c
k=l.d
j=k.d
i=j.c
if(m>=i||i<=0)throw A.d(A.a3(u.u))
m=q.b
s=2
return A.m(k.M(m.a.a,j.b),$async$$0)
case 2:p=b
s=3
return A.m(l.d.N(m.a.a,J.eu(p)),$async$$0)
case 3:o=b
l=l.d
h=m
s=4
return A.m(l.J(o,l.d.b),$async$$0)
case 4:h.a=b;++n.a
s=5
return A.m(q.d.$0(),$async$$0)
case 5:return A.E(null,r)}})
return A.F($async$$0,r)},
$S:2}
A.a2.prototype={
aO(){return"CryptorError."+this.b}}
A.d1.prototype={}
A.ak.prototype={
gaZ(){if(this.b==null)return!1
return this.r},
X(a,b,c,d,e,f){return this.b9(a,b,c,d,e,f)},
b8(a,b,c,d,e){return this.X(null,a,b,c,d,e)},
b9(a,b,c,d,e,f){var s=0,r=A.G(t.H),q=this,p,o,n,m,l,k
var $async$X=A.H(function(g,h){if(g===1)return A.D(h,r)
while(true)switch(s){case 0:k=$.v()
k.i(B.f,"setupTransform "+c+" kind "+b,null,null)
q.f=b
if(a!=null){k.i(B.f,"setting codec on cryptor to "+a,null,null)
q.d=a}k=v.G.TransformStream
n=c==="encode"?A.fH(q.gbF()):A.fH(q.gbB())
m=t.N
p=A.b(new k(A.b(A.i(A.j(["transform",n],m,t.g)))))
try{A.b(A.b(d.pipeThrough(p)).pipeTo(f))}catch(j){o=A.M(j)
$.v().i(B.c,"e "+J.T(o),null,null)
if(q.w!==B.q){q.w=B.q
q.y.postMessage(A.i(A.j(["type","cryptorState","msgType","event","participantId",q.b,"state","internalError","error","Internal error: "+J.T(o)],m,t.T)))}}q.c=e
return A.E(null,r)}})
return A.F($async$X,r)},
aA(a,b){var s,r,q,p,o,n=null,m=t.a.a(a.data),l="",k=A.I(m,0,n)
if("type" in a){l=A.h(a.type)
$.v().i(B.b,"frameType: "+l,n,n)}if(b!=null&&b.toLowerCase()==="h264"){t.p.a(k)
s=A.jc(k)
for(m=s.length,r=k.length,q=0;q<s.length;s.length===m||(0,A.bd)(s),++q){p=s[q]
if(!(p<r))return A.e(k,p)
o=k[p]&31
switch(o){case 5:case 1:m=p+2
$.v().i(B.b,"unEncryptedBytes NALU of type "+o+", offset "+m,n,n)
return m
default:$.v().i(B.b,"skipping NALU of type "+o,n,n)
break}}throw A.d(A.a3("Could not find NALU"))}switch(l){case"key":return 10
case"delta":return 3
case"audio":return 1
default:return 0}},
b2(a){var s,r,q,p,o
new Uint8Array(0)
s=t.a.a(a.data)
r=A.I(s,0,null)
if("type" in a){q=A.h(a.type)
$.v().i(B.b,"frameType: "+q,null,null)}else q=""
p=A.p(A.b(a.getMetadata()).synchronizationSource)
if("rtpTimestamp" in A.b(a.getMetadata()))o=B.i.bU(A.p(A.b(a.getMetadata()).rtpTimestamp))
else o="timestamp" in a?A.p(A.fC(a.timestamp)):0
return new A.d1(q,p,o,r)},
ap(a,b,c){a.data=t.a.a(B.e.gH(c.az()))
b.enqueue(a)},
a6(a,b){return this.bG(A.b(a),A.b(b))},
bG(a6,a7){var s=0,r=A.G(t.H),q,p=2,o=[],n=this,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5
var $async$a6=A.H(function(a8,a9){if(a8===1){o.push(a9)
s=p}while(true)switch(s){case 0:p=4
d=!0
if(n.gaZ()){c=t.a
b=c.a(a6.data)
if(!(b.byteLength===0)){d=c.a(a6.data)
d=d.byteLength===0}}if(d){if(n.e.d.r){s=1
break}a7.enqueue(a6)
s=1
break}m=n.b2(a6)
d=$.v()
d.i(B.l,"encodeFunction: buffer "+m.d.length+", synchronizationSource "+m.b+" frameType "+m.a,null,null)
c=n.e.K(n.x)
l=c==null?null:c.b
k=n.x
if(l==null){if(n.w!==B.p){n.w=B.p
d=n.b
c=n.c
b=n.f
b===$&&A.au("kind")
n.y.postMessage(A.i(A.j(["type","cryptorState","msgType","event","participantId",d,"trackId",c,"kind",b,"state","missingKey","error","Missing key for track "+c],t.N,t.T)))}s=1
break}c=n.f
c===$&&A.au("kind")
j=c==="video"?n.aA(a6,n.d):1
b=m.b
a=m.c
a0=new DataView(new ArrayBuffer(12))
c=n.a
if(c.j(0,b)==null)c.v(0,b,$.es().au(65535))
a1=c.j(0,b)
if(a1==null)a1=0
a0.setUint32(0,b,!1)
a0.setUint32(4,a,!1)
a0.setUint32(8,a-B.i.a9(a1,65535),!1)
c.v(0,b,a1+1)
i=J.et(B.r.gH(a0))
h=new DataView(new ArrayBuffer(2))
c=h
c.$flags&2&&A.X(c,6)
J.eV(c,0,12)
c=h
b=A.p(k)
c.$flags&2&&A.X(c,6)
J.eV(c,1,b)
b=n.y
c=A.b(A.b(b.crypto).subtle)
a=t.N
a2=A.i(A.j(["name","AES-GCM","iv",i,"additionalData",B.e.B(m.d,0,j)],a,t.K))
if(a2==null)a2=A.J(a2)
a5=t.a
s=7
return A.m(A.ag(A.b(c.encrypt(a2,l,B.e.B(m.d,j,m.d.length))),t.X),$async$a6)
case 7:g=a5.a(a9)
d.i(B.b,"encodeFunction: encrypted buffer: "+m.d.length+", cipherText: "+A.I(g,0,null).length,null,null)
c=$.cQ()
f=new A.b2(c)
J.be(f,new Uint8Array(A.ar(B.e.B(m.d,0,j))))
J.be(f,A.I(g,0,null))
J.be(f,i)
J.be(f,J.et(J.eu(h)))
n.ap(a6,a7,f)
if(n.w!==B.j){n.w=B.j
b.postMessage(A.i(A.j(["type","cryptorState","msgType","event","participantId",n.b,"trackId",n.c,"kind",n.f,"state","ok","error","encryption ok"],a,t.T)))}d.i(B.b,"encodeFunction[CryptorError.kOk]: frame enqueued kind "+n.f+",codec "+A.c(n.d)+" headerLength: "+A.c(j)+",  timestamp: "+m.c+", ssrc: "+m.b+", data length: "+m.d.length+", encrypted length: "+f.az().length+", iv "+A.c(i),null,null)
p=2
s=6
break
case 4:p=3
a4=o.pop()
e=A.M(a4)
$.v().i(B.c,"encodeFunction encrypt: e "+J.T(e),null,null)
if(n.w!==B.y){n.w=B.y
d=n.b
c=n.c
b=n.f
b===$&&A.au("kind")
n.y.postMessage(A.i(A.j(["type","cryptorState","msgType","event","participantId",d,"trackId",c,"kind",b,"state","encryptError","error",J.T(e)],t.N,t.T)))}s=6
break
case 3:s=2
break
case 6:case 1:return A.E(q,r)
case 2:return A.D(o.at(-1),r)}})
return A.F($async$a6,r)},
R(a,b){return this.bC(A.b(a),A.b(b))},
bC(b0,b1){var s=0,r=A.G(t.H),q,p=2,o=[],n=this,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9
var $async$R=A.H(function(b2,b3){if(b2===1){o.push(b3)
s=p}while(true)switch(s){case 0:a6={}
a7=n.b2(b0)
a6.a=0
c=$.v()
c.i(B.l,"decodeFunction: frame lenght "+a7.d.length,null,null)
a6.b=a6.c=null
a6.d=n.x
if(!n.gaZ()||a7.d.length===0){n.z.b3()
if(n.e.d.r){s=1
break}c.i(B.l,"enqueing empty frame",null,null)
b1.enqueue(b0)
c.i(B.b,"enqueing silent frame",null,null)
s=1
break}b=n.e.d.e
if(b!=null){a=a7.d
a0=b.length
a1=a0+1
if(a.length>a1){a2=B.e.B(a7.d,a7.d.length-a0-1,a7.d.length-1)
c.i(B.b,"magicBytesBuffer "+A.c(a2)+", magicBytes "+A.c(b),null,null)
a=n.z
if(A.d5(a2,"[","]")===A.d5(b,"[","]")){++a.a
if(a.b==null)a.b=Date.now()
a.c=Date.now()
if(a.a<100)if(a.b!=null){a6=Date.now()
a=a.b
a.toString
a=a6-a<2000
a6=a}else a6=!0
else a6=!1
if(a6){a6=B.e.aE(a7.d,a7.d.length-1)
if(0>=a6.length){q=A.e(a6,0)
s=1
break}c.i(B.b,"ecodeFunction: skip uncrypted frame, type "+a6[0],null,null)
e=new A.b2($.cQ())
e.u(0,new Uint8Array(A.ar(B.e.B(a7.d,0,a7.d.length-a1))))
n.ap(b0,b1,e)
c.i(B.l,"ecodeFunction: enqueing silent frame",null,null)
b1.enqueue(b0)}else c.i(B.b,"ecodeFunction: SIF limit reached, dropping frame",null,null)
c.i(B.b,"ecodeFunction: enqueing silent frame",null,null)
b1.enqueue(b0)
s=1
break}else a.b3()}}p=4
b={}
a=n.f
a===$&&A.au("kind")
m=a==="video"?n.aA(b0,n.d):1
l=B.e.aE(a7.d,a7.d.length-2)
k=J.eU(l,0)
j=J.eU(l,1)
a0=a7.d
a1=a7.d
a3=k
if(typeof a3!=="number"){q=A.jg(a3)
s=1
break}i=B.e.B(a0,a1.length-a3-2,a7.d.length-2)
a4=a6.b=n.e.K(j)
a6.d=j
c.i(B.b,"decodeFunction: start decrypting frame headerLength "+A.c(m)+" "+a7.d.length+" frameTrailer "+A.c(l)+", ivLength "+A.c(k)+", keyIndex "+A.c(j)+", iv "+A.c(i),null,null)
if(a4==null||!n.e.c){if(n.w!==B.p){n.w=B.p
a6=n.b
c=n.c
n.y.postMessage(A.i(A.j(["type","cryptorState","msgType","event","participantId",a6,"trackId",c,"kind",n.f,"state","missingKey","error","Missing key for track "+c],t.N,t.T)))}s=1
break}b.a=a4
h=new A.d_(a6,b,n,i,a7,m,k)
g=new A.d0(a6,b,n,h)
p=8
s=11
return A.m(h.$0(),$async$R)
case 11:p=4
s=10
break
case 8:p=7
a8=o.pop()
f=A.M(a8)
n.w=B.q
c=$.v()
c.i(B.b,"decodeFunction: kInternalError catch "+A.c(f),null,null)
s=12
return A.m(g.$0(),$async$R)
case 12:s=10
break
case 7:s=4
break
case 10:b=a6.c
if(b==null){a6=A.a3(u.r)
throw A.d(a6)}a=n.e
a.r=0
a.c=!0
c.i(B.b,u.f+a7.d.length+", decrypted: "+A.I(b,0,null).length,null,null)
b=$.cQ()
e=new A.b2(b)
J.be(e,new Uint8Array(A.ar(B.e.B(a7.d,0,m))))
a6=a6.c
a6.toString
J.be(e,A.I(a6,0,null))
n.ap(b0,b1,e)
if(n.w!==B.j){n.w=B.j
n.y.postMessage(A.i(A.j(["type","cryptorState","msgType","event","participantId",n.b,"trackId",n.c,"kind",n.f,"state","ok","error","decryption ok"],t.N,t.T)))}c.i(B.l,"decodeFunction[CryptorError.kOk]: decryption success kind "+n.f+", headerLength: "+A.c(m)+", timestamp: "+a7.c+", ssrc: "+a7.b+", data length: "+a7.d.length+", decrypted length: "+e.az().length+", keyindex "+A.c(j)+" iv "+A.c(i),null,null)
p=2
s=6
break
case 4:p=3
a9=o.pop()
d=A.M(a9)
if(n.w!==B.x){n.w=B.x
a6=n.b
c=n.c
b=n.f
b===$&&A.au("kind")
n.y.postMessage(A.i(A.j(["type","cryptorState","msgType","event","participantId",a6,"trackId",c,"kind",b,"state","decryptError","error",J.T(d)],t.N,t.T)))}n.e.aY()
s=6
break
case 3:s=2
break
case 6:case 1:return A.E(q,r)
case 2:return A.D(o.at(-1),r)}})
return A.F($async$R,r)}}
A.d_.prototype={
$0(){var s=0,r=A.G(t.H),q=this,p,o,n,m,l,k,j,i,h,g,f
var $async$$0=A.H(function(a,b){if(a===1)return A.D(b,r)
while(true)switch(s){case 0:n=q.c
m=n.y
l=A.b(A.b(m.crypto).subtle)
k=q.e
j=k.d
i=q.f
h=t.N
g=A.i(A.j(["name","AES-GCM","iv",q.d,"additionalData",B.e.B(j,0,i)],h,t.K))
if(g==null)g=A.J(g)
p=q.b
f=t.a
s=2
return A.m(A.ag(A.b(l.decrypt(g,p.a.b,B.e.B(j,i,j.length-q.r-2))),t.X),$async$$0)
case 2:o=f.a(b)
j=q.a
j.c=o
i=$.v()
i.i(B.b,u.D+A.I(o,0,null).length,null,null)
l=j.c
if(l==null)throw A.d(A.a3("[decryptFrameInternal] could not decrypt"))
i.i(B.b,u.D+A.I(l,0,null).length,null,null)
s=p.a!==j.b?3:4
break
case 3:i.i(B.l,u.E,null,null)
s=5
return A.m(n.e.L(p.a,j.d),$async$$0)
case 5:case 4:l=n.w
if(l!==B.j&&l!==B.z&&j.a>0){i.i(B.b,"decodeFunction::decryptFrameInternal: KeyRatcheted: ssrc "+k.b+" timestamp "+k.c+" ratchetCount "+j.a+"  participantId: "+A.c(n.b),null,null)
i.i(B.b,"decodeFunction::decryptFrameInternal: ratchetKey: lastError != CryptorError.kKeyRatcheted, reset state to kKeyRatcheted",null,null)
n.w=B.z
l=n.b
k=n.c
n=n.f
n===$&&A.au("kind")
m.postMessage(A.i(A.j(["type","cryptorState","msgType","event","participantId",l,"trackId",k,"kind",n,"state","keyRatcheted","error","Key ratcheted ok"],h,t.T)))}return A.E(null,r)}})
return A.F($async$$0,r)},
$S:2}
A.d0.prototype={
$0(){var s=0,r=A.G(t.H),q=this,p,o,n,m,l,k,j,i,h
var $async$$0=A.H(function(a,b){if(a===1)return A.D(b,r)
while(true)switch(s){case 0:n=q.a
m=n.a
l=q.c
k=l.e
j=k.d
i=j.c
if(m>=i||i<=0)throw A.d(A.a3(u.u))
m=q.b
s=2
return A.m(k.M(m.a.a,j.b),$async$$0)
case 2:p=b
s=3
return A.m(l.e.N(m.a.a,J.eu(p)),$async$$0)
case 3:o=b
l=l.e
h=m
s=4
return A.m(l.J(o,l.d.b),$async$$0)
case 4:h.a=b;++n.a
s=5
return A.m(q.d.$0(),$async$$0)
case 5:return A.E(null,r)}})
return A.F($async$$0,r)},
$S:2}
A.d7.prototype={
k(a){var s=this
return"KeyOptions{sharedKey: "+s.a+", ratchetWindowSize: "+s.c+", failureTolerance: "+s.d+", uncryptedMagicBytes: "+A.c(s.e)+", ratchetSalt: "+A.c(s.b)+"}"}}
A.cj.prototype={
G(a){var s,r,q=this,p=q.c
if(p.a)return q.W()
s=q.d
r=s.j(0,a)
if(r==null){r=A.f9(p,a,q.a)
p=q.f
if(p.length!==0)r.b7(p)
s.v(0,a,r)}return r},
W(){var s=this,r=s.e
return r==null?s.e=A.f9(s.c,"shared-key",s.a):r}}
A.aW.prototype={}
A.cs.prototype={
aY(){var s=this,r=s.d.d
if(r<0)return
if(++s.r>r){$.v().i(B.c,"key for "+s.f+" is being marked as invalid",null,null)
s.c=!1}},
U(a){var s=0,r=A.G(t.E),q,p=2,o=[],n=this,m,l,k,j,i,h,g
var $async$U=A.H(function(b,c){if(b===1){o.push(c)
s=p}while(true)switch(s){case 0:j=n.K(a)
i=j==null?null:j.a
if(i==null){q=null
s=1
break}p=4
g=t.a
s=7
return A.m(A.ag(A.b(A.b(A.b(n.e.crypto).subtle).exportKey("raw",i)),t.X),$async$U)
case 7:m=g.a(c)
j=A.I(m,0,null)
q=j
s=1
break
p=2
s=6
break
case 4:p=3
h=o.pop()
l=A.M(h)
$.v().i(B.c,"exportKey: "+A.c(l),null,null)
q=null
s=1
break
s=6
break
case 3:s=2
break
case 6:case 1:return A.E(q,r)
case 2:return A.D(o.at(-1),r)}})
return A.F($async$U,r)},
E(a){var s=0,r=A.G(t.E),q,p=this,o,n,m,l
var $async$E=A.H(function(b,c){if(b===1)return A.D(c,r)
while(true)switch(s){case 0:m=p.K(a)
l=m==null?null:m.a
if(l==null){q=null
s=1
break}m=p.d.b
s=3
return A.m(p.M(l,m),$async$E)
case 3:o=c
s=5
return A.m(p.N(l,B.e.gH(o)),$async$E)
case 5:s=4
return A.m(p.J(c,m),$async$E)
case 4:n=c
s=6
return A.m(p.L(n,a==null?p.a:a),$async$E)
case 6:q=o
s=1
break
case 1:return A.E(q,r)}})
return A.F($async$E,r)},
N(a,b){var s=0,r=A.G(t.m),q,p=this,o
var $async$N=A.H(function(c,d){if(c===1)return A.D(d,r)
while(true)switch(s){case 0:o=t.m
s=3
return A.m(A.ag(A.eL(A.b(A.b(p.e.crypto).subtle),"importKey",["raw",t.a.a(b),A.J(A.b(a.algorithm).name),!1,t.c.a(A.i(A.N(["deriveBits","deriveKey"],t.s)))],o),o),$async$N)
case 3:q=d
s=1
break
case 1:return A.E(q,r)}})
return A.F($async$N,r)},
K(a){var s,r=this.b
r===$&&A.au("cryptoKeyRing")
s=a==null?this.a:a
if(!(s>=0&&s<r.length))return A.e(r,s)
return r[s]},
D(a,b){var s=0,r=A.G(t.H),q=this,p,o,n
var $async$D=A.H(function(c,d){if(c===1)return A.D(d,r)
while(true)switch(s){case 0:o=A.b(A.b(q.e.crypto).subtle)
n=t.N
n=A.i(A.j(["name","PBKDF2"],n,n))
if(n==null)n=A.J(n)
p=t.m
s=4
return A.m(A.ag(A.eL(o,"importKey",["raw",a,n,!1,t.c.a(A.i(A.N(["deriveBits","deriveKey"],t.s)))],p),p),$async$D)
case 4:s=3
return A.m(q.J(d,q.d.b),$async$D)
case 3:s=2
return A.m(q.L(d,b),$async$D)
case 2:q.r=0
q.c=!0
return A.E(null,r)}})
return A.F($async$D,r)},
b7(a){return this.D(a,0)},
L(a,b){var s=0,r=A.G(t.H),q=this,p
var $async$L=A.H(function(c,d){if(c===1)return A.D(d,r)
while(true)switch(s){case 0:$.v().i(B.a,"setKeySetFromMaterial: set new key, index: "+b,null,null)
if(b>=0){p=q.b
p===$&&A.au("cryptoKeyRing")
q.a=B.i.a9(b,p.length)}p=q.b
p===$&&A.au("cryptoKeyRing")
B.d.v(p,q.a,a)
return A.E(null,r)}})
return A.F($async$L,r)},
J(a,b){var s=0,r=A.G(t.x),q,p=this,o,n,m,l,k,j,i
var $async$J=A.H(function(c,d){if(c===1)return A.D(d,r)
while(true)switch(s){case 0:n=A.fX(A.h(A.b(a.algorithm).name),b)
m=A.b(A.b(p.e.crypto).subtle)
l=A.i(n)
if(l==null)l=A.J(l)
o=A.i(A.j(["name","AES-GCM","length",128],t.N,t.K))
if(o==null)o=A.J(o)
k=A
j=a
i=A
s=3
return A.m(A.ag(A.eL(m,"deriveKey",[l,a,o,!1,t.c.a(A.i(A.N(["encrypt","decrypt"],t.s)))],t.m),t.X),$async$J)
case 3:q=new k.aW(j,i.b(d))
s=1
break
case 1:return A.E(q,r)}})
return A.F($async$J,r)},
M(a,b){var s=0,r=A.G(t.p),q,p=this,o,n,m,l
var $async$M=A.H(function(c,d){if(c===1)return A.D(d,r)
while(true)switch(s){case 0:o=A.fX("PBKDF2",b)
n=A.b(A.b(p.e.crypto).subtle)
m=A.i(o)
if(m==null)m=A.J(m)
l=A
s=3
return A.m(A.ag(A.b(n.deriveBits(m,a,256)),t.a),$async$M)
case 3:q=l.I(d,0,null)
s=1
break
case 1:return A.E(q,r)}})
return A.F($async$M,r)}}
A.df.prototype={
b3(){var s=this
if(s.b==null)return
if(++s.d>s.a||Date.now()-s.c>2000)s.b4()},
b4(){this.a=this.d=0
this.b=null}}
A.e5.prototype={
$1(a){return t.j.a(a).c===this.a},
$S:1}
A.e0.prototype={
$1(a){return t.D.a(a).c===this.a},
$S:10}
A.ep.prototype={
$1(a){return t.j.a(a).c===this.a},
$S:1}
A.eq.prototype={
$1(a){return t.D.a(a).c===this.a},
$S:10}
A.eh.prototype={
$1(a){t.cH.a(a)
A.jp("["+a.d+"] "+a.a.a+": "+a.b)},
$S:22}
A.ei.prototype={
$1(a){var s,r,q,p,o,n,m,l,k,j,i,h,g=null
A.b(a)
s=$.v()
s.i(B.f,"Got onrtctransform event",g,g)
r=A.b(a.transformer)
r.handled=!0
q=A.b(r.options)
p=A.h(q.kind)
o=A.h(q.participantId)
n=A.h(q.trackId)
m=A.dS(q.codec)
l=A.h(q.msgType)
k=A.h(q.keyProviderId)
j=$.af.j(0,k)
if(j==null){s.i(B.c,"KeyProvider not found for "+k,g,g)
return}i=A.h_(o,n,j)
s=A.b(r.readable)
h=A.b(r.writable)
i.X(m==null?g:m,p,l,s,n,h)},
$S:11}
A.ek.prototype={
$1(d2){var s=0,r=A.G(t.P),q,p=2,o=[],n,m,l,k,j,i,h,g,f,e,d,c,b,a,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,b0,b1,b2,b3,b4,b5,b6,b7,b8,b9,c0,c1,c2,c3,c4,c5,c6,c7,c8,c9,d0,d1
var $async$$1=A.H(function(d3,d4){if(d3===1){o.push(d4)
s=p}while(true)switch(s){case 0:c6=t.f.a(A.fW(d2.data))
c7=c6.j(0,"msgType")
c8=A.dS(c6.j(0,"msgId"))
c9=$.v()
c9.i(B.a,"Got message "+A.c(c7)+", msgId "+A.c(c8),null,null)
case 3:switch(c7){case"keyProviderInit":s=5
break
case"keyProviderDispose":s=6
break
case"enable":s=7
break
case"decode":s=8
break
case"encode":s=9
break
case"removeTransform":s=10
break
case"setKey":s=11
break
case"setSharedKey":s=12
break
case"ratchetKey":s=13
break
case"ratchetSharedKey":s=14
break
case"setKeyIndex":s=15
break
case"exportKey":s=16
break
case"exportSharedKey":s=17
break
case"setSifTrailer":s=18
break
case"updateCodec":s=19
break
case"dispose":s=20
break
case"dataCryptorEncrypt":s=21
break
case"dataCryptorDecrypt":s=22
break
case"dataCryptorDispose":s=23
break
default:s=24
break}break
case 5:a0=c6.j(0,"keyOptions")
a1=A.h(c6.j(0,"keyProviderId"))
a2=J.e1(a0)
a3=A.cM(a2.j(a0,"sharedKey"))
a4=new Uint8Array(A.ar(B.n.I(A.h(a2.j(a0,"ratchetSalt")))))
a5=A.p(a2.j(a0,"ratchetWindowSize"))
a6=a2.j(a0,"failureTolerance")
a6=A.p(a6==null?-1:a6)
a7=a2.j(a0,"uncryptedMagicBytes")!=null?new Uint8Array(A.ar(B.n.I(A.h(a2.j(a0,"uncryptedMagicBytes"))))):null
a8=a2.j(a0,"keyRingSize")
a8=A.p(a8==null?16:a8)
a2=a2.j(a0,"discardFrameWhenCryptorNotReady")
a9=new A.d7(a3,a4,a5,a6,a7,a8,A.cM(a2==null?!1:a2))
c9.i(B.a,"Init with keyProviderOptions:\n "+a9.k(0),null,null)
c9=v.G
a2=A.b(c9.self)
a3=t.N
a4=new Uint8Array(0)
$.af.v(0,a1,new A.cj(a2,a9,A.br(a3,t.bW),a4))
A.b(c9.self).postMessage(A.i(A.j(["type","init","msgId",c8,"msgType","response"],a3,t.T)))
s=4
break
case 6:a1=A.h(c6.j(0,"keyProviderId"))
c9.i(B.a,"Dispose keyProvider "+a1,null,null)
$.af.bQ(0,a1)
A.b(v.G.self).postMessage(A.i(A.j(["type","dispose","msgId",c8,"msgType","response"],t.N,t.T)))
s=4
break
case 7:b0=A.cM(c6.j(0,"enabled"))
b1=A.h(c6.j(0,"trackId"))
a2=$.aP
a3=A.ae(a2)
a4=a3.h("aE<1>")
b2=A.f4(new A.aE(a2,a3.h("V(1)").a(new A.eb(b1)),a4),a4.h("f.E"))
for(a2=b2.length,a3=""+b0,a4="Set enable "+a3+" for trackId ",a5="setEnabled["+a3+u.h,b3=0;b3<b2.length;b2.length===a2||(0,A.bd)(b2),++b3){k=b2[b3]
c9.i(B.a,a4+k.c,null,null)
if(k.w!==B.j){c9.i(B.f,a5,null,null)
k.w=B.m}c9.i(B.a,"setEnabled for "+A.c(k.b)+", enabled: "+a3,null,null)
k.r=b0}A.b(v.G.self).postMessage(A.i(A.j(["type","cryptorEnabled","enable",b0,"msgId",c8,"msgType","response"],t.N,t.X)))
s=4
break
case 8:case 9:b4=c6.j(0,"kind")
b5=A.cM(c6.j(0,"exist"))
n=A.h(c6.j(0,"participantId"))
b1=c6.j(0,"trackId")
b6=A.b(c6.j(0,"readableStream"))
b7=A.b(c6.j(0,"writableStream"))
a1=A.h(c6.j(0,"keyProviderId"))
c9.i(B.a,"SetupTransform for kind "+A.c(b4)+", trackId "+A.c(b1)+", participantId "+n+", "+J.ew(b6).k(0)+" "+J.ew(b7).k(0)+"}",null,null)
b8=$.af.j(0,a1)
if(b8==null){c9.i(B.c,"KeyProvider not found for "+a1,null,null)
A.b(v.G.self).postMessage(A.i(A.j(["type","cryptorSetup","participantId",n,"trackId",b1,"exist",b5,"operation",c7,"error","KeyProvider not found","msgId",c8,"msgType","response"],t.N,t.z)))
s=1
break}A.h(b1)
k=A.h_(n,b1,b8)
A.h(c7)
s=25
return A.m(k.b8(A.h(b4),c7,b6,b1,b7),$async$$1)
case 25:A.b(v.G.self).postMessage(A.i(A.j(["type","cryptorSetup","participantId",n,"trackId",b1,"exist",b5,"operation",c7,"msgId",c8,"msgType","response"],t.N,t.z)))
k.w=B.m
s=4
break
case 10:b1=A.h(c6.j(0,"trackId"))
c9.i(B.a,"Removing trackId "+b1,null,null)
A.jt(b1)
A.b(v.G.self).postMessage(A.i(A.j(["type","cryptorRemoved","trackId",b1,"msgId",c8,"msgType","response"],t.N,t.T)))
s=4
break
case 11:case 12:b9=new Uint8Array(A.ar(B.n.I(A.h(c6.j(0,"key")))))
e=A.p(c6.j(0,"keyIndex"))
a1=A.h(c6.j(0,"keyProviderId"))
b8=$.af.j(0,a1)
if(b8==null){c9.i(B.c,"KeyProvider not found for "+a1,null,null)
A.b(v.G.self).postMessage(A.i(A.j(["type","setKey","error","KeyProvider not found","msgId",c8,"msgType","response"],t.N,t.T)))
s=1
break}a2=b8.c.a
a3=""+e
s=a2?26:28
break
case 26:c9.i(B.a,"Set SharedKey keyIndex "+a3,null,null)
c9.i(B.f,"setting shared key",null,null)
b8.f=b9
b8.W().D(b9,e)
s=27
break
case 28:n=A.h(c6.j(0,"participantId"))
c9.i(B.a,"Set key for participant "+n+", keyIndex "+a3,null,null)
s=29
return A.m(b8.G(n).D(b9,e),$async$$1)
case 29:case 27:A.b(v.G.self).postMessage(A.i(A.j(["type","setKey","participantId",c6.j(0,"participantId"),"sharedKey",a2,"keyIndex",e,"msgId",c8,"msgType","response"],t.N,t.z)))
s=4
break
case 13:case 14:e=c6.j(0,"keyIndex")
n=A.h(c6.j(0,"participantId"))
a1=A.h(c6.j(0,"keyProviderId"))
b8=$.af.j(0,a1)
if(b8==null){c9.i(B.c,"KeyProvider not found for "+a1,null,null)
A.b(v.G.self).postMessage(A.i(A.j(["type","setKey","error","KeyProvider not found","msgId",c8,"msgType","response"],t.N,t.T)))
s=1
break}a2=b8.c.a
s=a2?30:32
break
case 30:c9.i(B.a,"RatchetKey for SharedKey, keyIndex "+A.c(e),null,null)
s=33
return A.m(b8.W().E(A.eI(e)),$async$$1)
case 33:c0=d4
s=31
break
case 32:c9.i(B.a,"RatchetKey for participant "+n+", keyIndex "+A.c(e),null,null)
s=34
return A.m(b8.G(n).E(A.eI(e)),$async$$1)
case 34:c0=d4
case 31:c9=A.b(v.G.self)
a3=c0!=null?B.u.I(t.B.h("av.S").a(c0)):""
c9.postMessage(A.i(A.j(["type","ratchetKey","sharedKey",a2,"participantId",n,"newKey",a3,"keyIndex",e,"msgId",c8,"msgType","response"],t.N,t.z)))
s=4
break
case 15:e=c6.j(0,"index")
b1=A.h(c6.j(0,"trackId"))
c9.i(B.a,"Setup key index for track "+b1,null,null)
a2=$.aP
a3=A.ae(a2)
a4=a3.h("aE<1>")
b2=A.f4(new A.aE(a2,a3.h("V(1)").a(new A.ec(b1)),a4),a4.h("f.E"))
for(a2=b2.length,b3=0;b3<b2.length;b2.length===a2||(0,A.bd)(b2),++b3){c1=b2[b3]
c9.i(B.a,"Set keyIndex for trackId "+c1.c,null,null)
A.p(e)
if(c1.w!==B.j){c9.i(B.f,"setKeyIndex: lastError != CryptorError.kOk, reset state to kNew",null,null)
c1.w=B.m}c9.i(B.a,"setKeyIndex for "+A.c(c1.b)+", newIndex: "+e,null,null)
c1.x=e}A.b(v.G.self).postMessage(A.i(A.j(["type","setKeyIndex","keyIndex",e,"msgId",c8,"msgType","response"],t.N,t.z)))
s=4
break
case 16:case 17:e=A.p(c6.j(0,"keyIndex"))
n=A.h(c6.j(0,"participantId"))
a1=A.h(c6.j(0,"keyProviderId"))
b8=$.af.j(0,a1)
if(b8==null){c9.i(B.c,"KeyProvider not found for "+a1,null,null)
A.b(v.G.self).postMessage(A.i(A.j(["type","setKey","error","KeyProvider not found","msgId",c8,"msgType","response"],t.N,t.T)))
s=1
break}a2=""+e
s=b8.c.a?35:37
break
case 35:c9.i(B.a,"Export SharedKey keyIndex "+a2,null,null)
s=38
return A.m(b8.W().U(e),$async$$1)
case 38:b9=d4
s=36
break
case 37:c9.i(B.a,"Export key for participant "+n+", keyIndex "+a2,null,null)
s=39
return A.m(b8.G(n).U(e),$async$$1)
case 39:b9=d4
case 36:c9=A.b(v.G.self)
a2=b9!=null?B.u.I(t.B.h("av.S").a(b9)):""
c9.postMessage(A.i(A.j(["type","exportKey","participantId",n,"keyIndex",e,"exportedKey",a2,"msgId",c8,"msgType","response"],t.N,t.X)))
s=4
break
case 18:c2=new Uint8Array(A.ar(B.n.I(A.h(c6.j(0,"sifTrailer")))))
a1=A.h(c6.j(0,"keyProviderId"))
b8=$.af.j(0,a1)
if(b8==null){c9.i(B.c,"KeyProvider not found for "+a1,null,null)
A.b(v.G.self).postMessage(A.i(A.j(["type","setKey","error","KeyProvider not found","msgId",c8,"msgType","response"],t.N,t.T)))
s=1
break}b8.c.e=c2
c9.i(B.a,"SetSifTrailer = "+A.c(c2),null,null)
for(a2=$.aP,a3=a2.length,b3=0;b3<a2.length;a2.length===a3||(0,A.bd)(a2),++b3){c1=a2[b3]
c9.i(B.a,"setSifTrailer for "+A.c(c1.b)+", magicBytes: "+A.c(c2),null,null)
c1.e.d.e=c2}A.b(v.G.self).postMessage(A.i(A.j(["type","setSifTrailer","msgId",c8,"msgType","response"],t.N,t.T)))
s=4
break
case 19:c3=A.h(c6.j(0,"codec"))
b1=A.h(c6.j(0,"trackId"))
c9.i(B.a,"Update codec for trackId "+b1+", codec "+c3,null,null)
k=A.ay($.aP,new A.ed(b1),t.j)
if(k!=null){if(k.w!==B.j){c9.i(B.f,"updateCodec["+c3+u.h,null,null)
k.w=B.m}c9.i(B.a,"updateCodec for "+A.c(k.b)+", codec: "+c3,null,null)
k.d=c3}A.b(v.G.self).postMessage(A.i(A.j(["type","updateCodec","msgId",c8,"msgType","response"],t.N,t.T)))
s=4
break
case 20:b1=A.h(c6.j(0,"trackId"))
c9.i(B.a,"Dispose for trackId "+b1,null,null)
k=A.ay($.aP,new A.ee(b1),t.j)
c9=v.G
a2=t.N
a3=t.T
if(k!=null){k.w=B.L
A.b(c9.self).postMessage(A.i(A.j(["type","cryptorDispose","participantId",k.b,"trackId",b1,"msgId",c8,"msgType","response"],a2,a3)))}else A.b(c9.self).postMessage(A.i(A.j(["type","cryptorDispose","error","cryptor not found","msgId",c8,"msgType","response"],a2,a3)))
s=4
break
case 21:n=A.h(c6.j(0,"participantId"))
m=t.p.a(c6.j(0,"data"))
e=A.p(c6.j(0,"keyIndex"))
l=A.h(c6.j(0,"dataCryptorId"))
c4=A.h(c6.j(0,"algorithm"))
if(A.ay(B.A,new A.ef(c4),t.b)==null){A.b(v.G.self).postMessage(A.i(A.j(["type","dataCryptorEncrypt","error","algorithm not found","msgId",c8,"msgType","response"],t.N,t.T)))
s=1
break}c9.i(B.a,"Encrypt for dataCryptorId "+A.c(l)+", participantId "+A.c(n)+", keyIndex "+e+", data length "+J.aQ(m)+", algorithm "+c4,null,null)
a1=A.h(c6.j(0,"keyProviderId"))
b8=$.af.j(0,a1)
if(b8==null){c9.i(B.c,"KeyProvider not found for "+a1,null,null)
A.b(v.G.self).postMessage(A.i(A.j(["type","dataCryptorEncrypt","error","KeyProvider not found","msgId",c8,"msgType","response"],t.N,t.T)))
s=1
break}k=A.fY(n,l,b8)
p=41
s=44
return A.m(k.a7(k.d,m),$async$$1)
case 44:j=d4
A.b(v.G.self).postMessage(A.i(A.j(["type","dataCryptorEncrypt","participantId",n,"dataCryptorId",l,"data",j.a,"keyIndex",j.b,"iv",j.c,"msgId",c8,"msgType","response"],t.N,t.X)))
p=2
s=43
break
case 41:p=40
d0=o.pop()
i=A.M(d0)
$.v().i(B.c,"Error encrypting data: "+A.c(i),null,null)
A.b(v.G.self).postMessage(A.i(A.j(["type","dataCryptorEncrypt","error",J.T(i),"msgId",c8,"msgType","response"],t.N,t.T)))
s=43
break
case 40:s=2
break
case 43:s=4
break
case 22:h=A.h(c6.j(0,"participantId"))
a2=t.p
g=a2.a(c6.j(0,"data"))
f=a2.a(c6.j(0,"iv"))
e=A.p(c6.j(0,"keyIndex"))
d=A.h(c6.j(0,"dataCryptorId"))
c4=A.h(c6.j(0,"algorithm"))
if(A.ay(B.A,new A.eg(c4),t.b)==null){A.b(v.G.self).postMessage(A.i(A.j(["type","dataCryptorDecrypt","error","algorithm not found","msgId",c8,"msgType","response"],t.N,t.T)))
s=1
break}c9.i(B.a,"Decrypt for dataCryptorId "+A.c(d)+", participantId "+A.c(h)+", keyIndex "+A.c(e)+", data length "+J.aQ(g)+", algorithm "+c4,null,null)
a1=A.h(c6.j(0,"keyProviderId"))
b8=$.af.j(0,a1)
if(b8==null){c9.i(B.c,"KeyProvider not found for "+a1,null,null)
A.b(v.G.self).postMessage(A.i(A.j(["type","dataCryptorDecrypt","error","KeyProvider not found","msgId",c8,"msgType","response"],t.N,t.T)))
s=1
break}c=A.fY(h,d,b8)
p=46
s=49
return A.m(c.S(c.d,new A.bj(g,e,f)),$async$$1)
case 49:b=d4
A.b(v.G.self).postMessage(A.i(A.j(["type","dataCryptorDecrypt","participantId",h,"dataCryptorId",d,"data",b,"msgId",c8,"msgType","response"],t.N,t.X)))
p=2
s=48
break
case 46:p=45
d1=o.pop()
a=A.M(d1)
$.v().i(B.c,"Error decrypting data: "+A.c(a),null,null)
A.b(v.G.self).postMessage(A.i(A.j(["type","dataCryptorDecrypt","error",J.T(a),"msgId",c8,"msgType","response"],t.N,t.T)))
s=48
break
case 45:s=2
break
case 48:s=4
break
case 23:l=A.h(c6.j(0,"dataCryptorId"))
c9.i(B.a,"Dispose for dataCryptorId "+l,null,null)
A.ju(l)
A.b(v.G.self).postMessage(A.i(A.j(["type","dataCryptorDispose","dataCryptorId",l,"msgId",c8,"msgType","response"],t.N,t.T)))
s=4
break
case 24:c9.i(B.c,"Unknown message kind "+c6.k(0),null,null)
case 4:case 1:return A.E(q,r)
case 2:return A.D(o.at(-1),r)}})
return A.F($async$$1,r)},
$S:23}
A.eb.prototype={
$1(a){return t.j.a(a).c===this.a},
$S:1}
A.ec.prototype={
$1(a){return t.j.a(a).c===this.a},
$S:1}
A.ed.prototype={
$1(a){return t.j.a(a).c===this.a},
$S:1}
A.ee.prototype={
$1(a){return t.j.a(a).c===this.a},
$S:1}
A.ef.prototype={
$1(a){return t.b.a(a).b===this.a},
$S:12}
A.eg.prototype={
$1(a){return t.b.a(a).b===this.a},
$S:12}
A.ej.prototype={
$1(a){this.a.$1(A.b(a))},
$S:11};(function aliases(){var s=J.al.prototype
s.bb=s.k
s=A.aF.prototype
s.bc=s.aa})();(function installTearOffs(){var s=hunkHelpers._static_1,r=hunkHelpers._static_0,q=hunkHelpers._static_2,p=hunkHelpers._instance_2u,o=hunkHelpers._instance_0u
s(A,"j3","hT",4)
s(A,"j4","hU",4)
s(A,"j5","hV",4)
r(A,"fU","iX",0)
q(A,"j7","iQ",7)
r(A,"j6","iP",0)
p(A.x.prototype,"gbi","bj",7)
o(A.b3.prototype,"gbp","bq",0)
var n
p(n=A.ak.prototype,"gbF","a6",9)
p(n,"gbB","R",9)})();(function inheritance(){var s=hunkHelpers.mixin,r=hunkHelpers.inherit,q=hunkHelpers.inheritMany
r(A.k,null)
q(A.k,[A.eA,J.cd,A.bC,J.bf,A.b2,A.w,A.de,A.f,A.aA,A.bt,A.bH,A.L,A.dj,A.dd,A.bk,A.bU,A.aj,A.aC,A.d8,A.bp,A.cL,A.a0,A.cG,A.dO,A.dM,A.cC,A.O,A.b_,A.ad,A.aF,A.cE,A.aG,A.x,A.cD,A.bM,A.cH,A.b3,A.cJ,A.c_,A.bP,A.u,A.av,A.c9,A.du,A.dt,A.ca,A.dv,A.cr,A.bD,A.dw,A.cZ,A.y,A.cK,A.cx,A.dc,A.dH,A.am,A.aB,A.aX,A.bj,A.aw,A.d1,A.ak,A.d7,A.cj,A.aW,A.cs,A.df])
q(J.cd,[J.cf,J.bm,J.bn,J.aU,J.aV,J.ch,J.aT])
q(J.bn,[J.al,J.z,A.an,A.bx])
q(J.al,[J.ct,J.bE,J.a6])
r(J.ce,A.bC)
r(J.d6,J.z)
q(J.ch,[J.bl,J.cg])
q(A.w,[A.bo,A.ab,A.ci,A.cB,A.cv,A.cF,A.c3,A.Z,A.bF,A.cA,A.aD,A.c8])
q(A.f,[A.l,A.a8,A.aE])
q(A.l,[A.a7,A.bq,A.bO])
r(A.bi,A.a8)
r(A.a9,A.a7)
r(A.bA,A.ab)
q(A.aj,[A.c6,A.c7,A.cy,A.e6,A.e8,A.dq,A.dp,A.dT,A.dL,A.dF,A.dh,A.ea,A.en,A.eo,A.dZ,A.e5,A.e0,A.ep,A.eq,A.eh,A.ei,A.ek,A.eb,A.ec,A.ed,A.ee,A.ef,A.eg,A.ej])
q(A.cy,[A.cw,A.aR])
q(A.aC,[A.az,A.bN])
q(A.c7,[A.e7,A.dU,A.dX,A.dG,A.db])
r(A.aY,A.an)
q(A.bx,[A.bu,A.C])
q(A.C,[A.bQ,A.bS])
r(A.bR,A.bQ)
r(A.bv,A.bR)
r(A.bT,A.bS)
r(A.bw,A.bT)
q(A.bv,[A.ck,A.cl])
q(A.bw,[A.cm,A.cn,A.co,A.cp,A.cq,A.by,A.bz])
r(A.bW,A.cF)
q(A.c6,[A.dr,A.ds,A.dN,A.dx,A.dB,A.dA,A.dz,A.dy,A.dE,A.dD,A.dC,A.di,A.dJ,A.dW,A.dK,A.da,A.cU,A.cV,A.d_,A.d0])
r(A.b5,A.b_)
r(A.bJ,A.b5)
r(A.b1,A.bJ)
r(A.bK,A.ad)
r(A.ao,A.bK)
r(A.bV,A.aF)
r(A.bI,A.cE)
r(A.bL,A.bM)
r(A.cI,A.c_)
r(A.b4,A.bN)
r(A.c5,A.av)
q(A.c9,[A.cT,A.cS])
q(A.Z,[A.aZ,A.cc])
q(A.dv,[A.ah,A.a2])
s(A.bQ,A.u)
s(A.bR,A.L)
s(A.bS,A.u)
s(A.bT,A.L)})()
var v={G:typeof self!="undefined"?self:globalThis,typeUniverse:{eC:new Map(),tR:{},eT:{},tPV:{},sEA:[]},mangledGlobalNames:{a:"int",n:"double",aO:"num",a5:"String",V:"bool",y:"Null",r:"List",k:"Object",bs:"Map",q:"JSObject"},mangledNames:{},types:["~()","V(ak)","a_<~>()","~(@)","~(~())","y(@)","y()","~(k,a1)","k?(k?)","~(q,q)","V(aw)","y(q)","V(ah)","@(@)","@(@,a5)","@(a5)","y(~())","y(@,a1)","~(a,@)","y(k,a1)","~(k?,k?)","aX()","~(aB)","a_<y>(q)"],interceptorsByTag:null,leafTags:null,arrayRti:Symbol("$ti")}
A.id(v.typeUniverse,JSON.parse('{"a6":"al","ct":"al","bE":"al","jx":"an","cf":{"V":[],"o":[]},"bm":{"y":[],"o":[]},"bn":{"q":[]},"al":{"q":[]},"z":{"r":["1"],"l":["1"],"q":[],"f":["1"]},"ce":{"bC":[]},"d6":{"z":["1"],"r":["1"],"l":["1"],"q":[],"f":["1"]},"bf":{"a4":["1"]},"ch":{"n":[],"aO":[]},"bl":{"n":[],"a":[],"aO":[],"o":[]},"cg":{"n":[],"aO":[],"o":[]},"aT":{"a5":[],"fa":[],"o":[]},"b2":{"hm":[]},"bo":{"w":[]},"l":{"f":["1"]},"a7":{"l":["1"],"f":["1"]},"aA":{"a4":["1"]},"a8":{"f":["2"],"f.E":"2"},"bi":{"a8":["1","2"],"l":["2"],"f":["2"],"f.E":"2"},"bt":{"a4":["2"]},"a9":{"a7":["2"],"l":["2"],"f":["2"],"f.E":"2","a7.E":"2"},"aE":{"f":["1"],"f.E":"1"},"bH":{"a4":["1"]},"bA":{"ab":[],"w":[]},"ci":{"w":[]},"cB":{"w":[]},"bU":{"a1":[]},"aj":{"ax":[]},"c6":{"ax":[]},"c7":{"ax":[]},"cy":{"ax":[]},"cw":{"ax":[]},"aR":{"ax":[]},"cv":{"w":[]},"az":{"aC":["1","2"],"f3":["1","2"],"bs":["1","2"]},"bq":{"l":["1"],"f":["1"],"f.E":"1"},"bp":{"a4":["1"]},"aY":{"an":[],"q":[],"bg":[],"o":[]},"an":{"q":[],"bg":[],"o":[]},"bx":{"q":[]},"cL":{"bg":[]},"bu":{"ez":[],"q":[],"o":[]},"C":{"P":["1"],"q":[]},"bv":{"u":["n"],"C":["n"],"r":["n"],"P":["n"],"l":["n"],"q":[],"f":["n"],"L":["n"]},"bw":{"u":["a"],"C":["a"],"r":["a"],"P":["a"],"l":["a"],"q":[],"f":["a"],"L":["a"]},"ck":{"cX":[],"u":["n"],"C":["n"],"r":["n"],"P":["n"],"l":["n"],"q":[],"f":["n"],"L":["n"],"o":[],"u.E":"n"},"cl":{"cY":[],"u":["n"],"C":["n"],"r":["n"],"P":["n"],"l":["n"],"q":[],"f":["n"],"L":["n"],"o":[],"u.E":"n"},"cm":{"d2":[],"u":["a"],"C":["a"],"r":["a"],"P":["a"],"l":["a"],"q":[],"f":["a"],"L":["a"],"o":[],"u.E":"a"},"cn":{"d3":[],"u":["a"],"C":["a"],"r":["a"],"P":["a"],"l":["a"],"q":[],"f":["a"],"L":["a"],"o":[],"u.E":"a"},"co":{"d4":[],"u":["a"],"C":["a"],"r":["a"],"P":["a"],"l":["a"],"q":[],"f":["a"],"L":["a"],"o":[],"u.E":"a"},"cp":{"dl":[],"u":["a"],"C":["a"],"r":["a"],"P":["a"],"l":["a"],"q":[],"f":["a"],"L":["a"],"o":[],"u.E":"a"},"cq":{"dm":[],"u":["a"],"C":["a"],"r":["a"],"P":["a"],"l":["a"],"q":[],"f":["a"],"L":["a"],"o":[],"u.E":"a"},"by":{"dn":[],"u":["a"],"C":["a"],"r":["a"],"P":["a"],"l":["a"],"q":[],"f":["a"],"L":["a"],"o":[],"u.E":"a"},"bz":{"cz":[],"u":["a"],"C":["a"],"r":["a"],"P":["a"],"l":["a"],"q":[],"f":["a"],"L":["a"],"o":[],"u.E":"a"},"cF":{"w":[]},"bW":{"ab":[],"w":[]},"ad":{"b0":["1"],"ap":["1"]},"O":{"w":[]},"b1":{"bJ":["1"],"b5":["1"],"b_":["1"]},"ao":{"bK":["1"],"ad":["1"],"b0":["1"],"ap":["1"]},"aF":{"fh":["1"],"fv":["1"],"ap":["1"]},"bV":{"aF":["1"],"fh":["1"],"fv":["1"],"ap":["1"]},"bI":{"cE":["1"]},"x":{"a_":["1"]},"bJ":{"b5":["1"],"b_":["1"]},"bK":{"ad":["1"],"b0":["1"],"ap":["1"]},"b5":{"b_":["1"]},"bL":{"bM":["1"]},"b3":{"b0":["1"]},"c_":{"fm":[]},"cI":{"c_":[],"fm":[]},"bN":{"aC":["1","2"],"bs":["1","2"]},"b4":{"bN":["1","2"],"aC":["1","2"],"bs":["1","2"]},"bO":{"l":["1"],"f":["1"],"f.E":"1"},"bP":{"a4":["1"]},"aC":{"bs":["1","2"]},"c5":{"av":["r<a>","a5"],"av.S":"r<a>"},"n":{"aO":[]},"a":{"aO":[]},"r":{"l":["1"],"f":["1"]},"a5":{"fa":[]},"c3":{"w":[]},"ab":{"w":[]},"Z":{"w":[]},"aZ":{"w":[]},"cc":{"w":[]},"bF":{"w":[]},"cA":{"w":[]},"aD":{"w":[]},"c8":{"w":[]},"cr":{"w":[]},"bD":{"w":[]},"cK":{"a1":[]},"d4":{"r":["a"],"l":["a"],"f":["a"]},"cz":{"r":["a"],"l":["a"],"f":["a"]},"dn":{"r":["a"],"l":["a"],"f":["a"]},"d2":{"r":["a"],"l":["a"],"f":["a"]},"dl":{"r":["a"],"l":["a"],"f":["a"]},"d3":{"r":["a"],"l":["a"],"f":["a"]},"dm":{"r":["a"],"l":["a"],"f":["a"]},"cX":{"r":["n"],"l":["n"],"f":["n"]},"cY":{"r":["n"],"l":["n"],"f":["n"]}}'))
A.ic(v.typeUniverse,JSON.parse('{"l":1,"C":1,"bM":1,"c9":2}'))
var u={o:"Cannot fire new event. Controller is already firing an event",c:"Error handler must accept one Object or one Object and a StackTrace as arguments, and return a value of the returned future's type",r:"[decodeFunction] decryption failed even after ratchting",u:"[ratchedKeyInternal] cannot ratchet anymore",h:"]: lastError != CryptorError.kOk, reset state to kNew",f:"decodeFunction: decryption success, buffer length ",D:"decodeFunction::decryptFrameInternal: decrypted: ",E:"decodeFunction::decryptFrameInternal: ratchetKey: decryption ok, newState: kKeyRatcheted"}
var t=(function rtii(){var s=A.ba
return{h:s("@<~>"),b:s("ah"),n:s("O"),B:s("c5"),J:s("bg"),V:s("ez"),D:s("aw"),d:s("l<@>"),C:s("w"),G:s("cX"),q:s("cY"),j:s("ak"),Z:s("ax"),O:s("d2"),k:s("d3"),U:s("d4"),R:s("f<@>"),e:s("f<a>"),s:s("z<a5>"),r:s("z<@>"),t:s("z<a>"),c:s("z<k?>"),u:s("bm"),m:s("q"),g:s("a6"),w:s("P<@>"),x:s("aW"),cK:s("r<@>"),L:s("r<a>"),bG:s("r<aW?>"),cH:s("aB"),I:s("aX"),f:s("bs<@,@>"),a:s("aY"),P:s("y"),K:s("k"),bW:s("cs"),cY:s("jz"),l:s("a1"),N:s("a5"),a4:s("o"),b7:s("ab"),c0:s("dl"),bk:s("dm"),ca:s("dn"),p:s("cz"),cr:s("bE"),_:s("x<@>"),aQ:s("x<a>"),A:s("b4<k?,k?>"),W:s("bV<aB>"),y:s("V"),c1:s("V(k)"),i:s("n"),z:s("@"),bd:s("@()"),v:s("@(k)"),Q:s("@(k,a1)"),S:s("a"),a5:s("bj?"),bc:s("a_<y>?"),b1:s("q?"),aF:s("aW?"),X:s("k?"),T:s("a5?"),E:s("cz?"),F:s("aG<@,@>?"),cG:s("V?"),dd:s("n?"),a3:s("a?"),ae:s("aO?"),Y:s("~()?"),o:s("aO"),H:s("~"),M:s("~()"),bo:s("~(k)"),aD:s("~(k,a1)")}})();(function constants(){var s=hunkHelpers.makeConstList
B.M=J.cd.prototype
B.d=J.z.prototype
B.i=J.bl.prototype
B.k=J.aT.prototype
B.N=J.a6.prototype
B.O=J.bn.prototype
B.r=A.bu.prototype
B.e=A.bz.prototype
B.B=J.ct.prototype
B.t=J.bE.prototype
B.n=new A.cS()
B.u=new A.cT()
B.v=function getTagFallback(o) {
  var s = Object.prototype.toString.call(o);
  return s.substring(8, s.length - 1);
}
B.E=function() {
  var toStringFunction = Object.prototype.toString;
  function getTag(o) {
    var s = toStringFunction.call(o);
    return s.substring(8, s.length - 1);
  }
  function getUnknownTag(object, tag) {
    if (/^HTML[A-Z].*Element$/.test(tag)) {
      var name = toStringFunction.call(object);
      if (name == "[object Object]") return null;
      return "HTMLElement";
    }
  }
  function getUnknownTagGenericBrowser(object, tag) {
    if (object instanceof HTMLElement) return "HTMLElement";
    return getUnknownTag(object, tag);
  }
  function prototypeForTag(tag) {
    if (typeof window == "undefined") return null;
    if (typeof window[tag] == "undefined") return null;
    var constructor = window[tag];
    if (typeof constructor != "function") return null;
    return constructor.prototype;
  }
  function discriminator(tag) { return null; }
  var isBrowser = typeof HTMLElement == "function";
  return {
    getTag: getTag,
    getUnknownTag: isBrowser ? getUnknownTagGenericBrowser : getUnknownTag,
    prototypeForTag: prototypeForTag,
    discriminator: discriminator };
}
B.J=function(getTagFallback) {
  return function(hooks) {
    if (typeof navigator != "object") return hooks;
    var userAgent = navigator.userAgent;
    if (typeof userAgent != "string") return hooks;
    if (userAgent.indexOf("DumpRenderTree") >= 0) return hooks;
    if (userAgent.indexOf("Chrome") >= 0) {
      function confirm(p) {
        return typeof window == "object" && window[p] && window[p].name == p;
      }
      if (confirm("Window") && confirm("HTMLElement")) return hooks;
    }
    hooks.getTag = getTagFallback;
  };
}
B.F=function(hooks) {
  if (typeof dartExperimentalFixupGetTag != "function") return hooks;
  hooks.getTag = dartExperimentalFixupGetTag(hooks.getTag);
}
B.I=function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Firefox") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "GeoGeolocation": "Geolocation",
    "Location": "!Location",
    "WorkerMessageEvent": "MessageEvent",
    "XMLDocument": "!Document"};
  function getTagFirefox(o) {
    var tag = getTag(o);
    return quickMap[tag] || tag;
  }
  hooks.getTag = getTagFirefox;
}
B.H=function(hooks) {
  if (typeof navigator != "object") return hooks;
  var userAgent = navigator.userAgent;
  if (typeof userAgent != "string") return hooks;
  if (userAgent.indexOf("Trident/") == -1) return hooks;
  var getTag = hooks.getTag;
  var quickMap = {
    "BeforeUnloadEvent": "Event",
    "DataTransfer": "Clipboard",
    "HTMLDDElement": "HTMLElement",
    "HTMLDTElement": "HTMLElement",
    "HTMLPhraseElement": "HTMLElement",
    "Position": "Geoposition"
  };
  function getTagIE(o) {
    var tag = getTag(o);
    var newTag = quickMap[tag];
    if (newTag) return newTag;
    if (tag == "Object") {
      if (window.DataView && (o instanceof window.DataView)) return "DataView";
    }
    return tag;
  }
  function prototypeForTagIE(tag) {
    var constructor = window[tag];
    if (constructor == null) return null;
    return constructor.prototype;
  }
  hooks.getTag = getTagIE;
  hooks.prototypeForTag = prototypeForTagIE;
}
B.G=function(hooks) {
  var getTag = hooks.getTag;
  var prototypeForTag = hooks.prototypeForTag;
  function getTagFixed(o) {
    var tag = getTag(o);
    if (tag == "Document") {
      if (!!o.xmlVersion) return "!Document";
      return "!HTMLDocument";
    }
    return tag;
  }
  function prototypeForTagFixed(tag) {
    if (tag == "Document") return null;
    return prototypeForTag(tag);
  }
  hooks.getTag = getTagFixed;
  hooks.prototypeForTag = prototypeForTagFixed;
}
B.w=function(hooks) { return hooks; }

B.K=new A.cr()
B.a1=new A.de()
B.h=new A.cI()
B.o=new A.cK()
B.m=new A.a2("kNew")
B.j=new A.a2("kOk")
B.x=new A.a2("kDecryptError")
B.y=new A.a2("kEncryptError")
B.p=new A.a2("kMissingKey")
B.z=new A.a2("kKeyRatcheted")
B.q=new A.a2("kInternalError")
B.L=new A.a2("kDisposed")
B.a=new A.am("CONFIG",700)
B.b=new A.am("FINER",400)
B.l=new A.am("FINE",500)
B.f=new A.am("INFO",800)
B.c=new A.am("WARNING",900)
B.C=new A.ah("kAesGcm")
B.D=new A.ah("kAesCbc")
B.A=s([B.C,B.D],A.ba("z<ah>"))
B.P=A.Y("bg")
B.Q=A.Y("ez")
B.R=A.Y("cX")
B.S=A.Y("cY")
B.T=A.Y("d2")
B.U=A.Y("d3")
B.V=A.Y("d4")
B.W=A.Y("q")
B.X=A.Y("k")
B.Y=A.Y("dl")
B.Z=A.Y("dm")
B.a_=A.Y("dn")
B.a0=A.Y("cz")})();(function staticFields(){$.dI=null
$.S=A.N([],A.ba("z<k>"))
$.fb=null
$.eZ=null
$.eY=null
$.fZ=null
$.fT=null
$.h1=null
$.e_=null
$.e9=null
$.eN=null
$.b6=null
$.c0=null
$.c1=null
$.eK=!1
$.t=B.h
$.f6=0
$.hz=A.br(t.N,t.I)
$.aP=A.N([],A.ba("z<ak>"))
$.eR=A.N([],A.ba("z<aw>"))
$.af=A.br(t.N,A.ba("cj"))})();(function lazyInitializers(){var s=hunkHelpers.lazyFinal,r=hunkHelpers.lazy
s($,"jv","er",()=>A.jd("_$dart_dartClosure"))
s($,"jO","cQ",()=>A.f8(0))
s($,"jQ","hh",()=>A.N([new J.ce()],A.ba("z<bC>")))
s($,"jB","h4",()=>A.ac(A.dk({
toString:function(){return"$receiver$"}})))
s($,"jC","h5",()=>A.ac(A.dk({$method$:null,
toString:function(){return"$receiver$"}})))
s($,"jD","h6",()=>A.ac(A.dk(null)))
s($,"jE","h7",()=>A.ac(function(){var $argumentsExpr$="$arguments$"
try{null.$method$($argumentsExpr$)}catch(q){return q.message}}()))
s($,"jH","ha",()=>A.ac(A.dk(void 0)))
s($,"jI","hb",()=>A.ac(function(){var $argumentsExpr$="$arguments$"
try{(void 0).$method$($argumentsExpr$)}catch(q){return q.message}}()))
s($,"jG","h9",()=>A.ac(A.fk(null)))
s($,"jF","h8",()=>A.ac(function(){try{null.$method$}catch(q){return q.message}}()))
s($,"jK","hd",()=>A.ac(A.fk(void 0)))
s($,"jJ","hc",()=>A.ac(function(){try{(void 0).$method$}catch(q){return q.message}}()))
s($,"jL","eS",()=>A.hS())
s($,"jN","hf",()=>new Int8Array(A.ar(A.N([-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-2,-1,-2,-2,-2,-2,-2,62,-2,62,-2,63,52,53,54,55,56,57,58,59,60,61,-2,-2,-2,-1,-2,-2,-2,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,-2,-2,-2,-2,63,-2,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,-2,-2,-2,-2,-2],t.t))))
r($,"jM","he",()=>A.f8(0))
s($,"jP","hg",()=>A.em(B.X))
s($,"jy","es",()=>{var q=new A.dH(A.hB(8))
q.bd()
return q})
s($,"jw","cP",()=>A.d9(""))
s($,"jS","v",()=>A.d9("E2EE.Worker"))})();(function nativeSupport(){!function(){var s=function(a){var m={}
m[a]=1
return Object.keys(hunkHelpers.convertToFastObject(m))[0]}
v.getIsolateTag=function(a){return s("___dart_"+a+v.isolateTag)}
var r="___dart_isolate_tags_"
var q=Object[r]||(Object[r]=Object.create(null))
var p="_ZxYxX"
for(var o=0;;o++){var n=s(p+"_"+o+"_")
if(!(n in q)){q[n]=1
v.isolateTag=n
break}}v.dispatchPropertyName=v.getIsolateTag("dispatch_record")}()
hunkHelpers.setOrUpdateInterceptorsByTag({SharedArrayBuffer:A.an,ArrayBuffer:A.aY,ArrayBufferView:A.bx,DataView:A.bu,Float32Array:A.ck,Float64Array:A.cl,Int16Array:A.cm,Int32Array:A.cn,Int8Array:A.co,Uint16Array:A.cp,Uint32Array:A.cq,Uint8ClampedArray:A.by,CanvasPixelArray:A.by,Uint8Array:A.bz})
hunkHelpers.setOrUpdateLeafTags({SharedArrayBuffer:true,ArrayBuffer:true,ArrayBufferView:false,DataView:true,Float32Array:true,Float64Array:true,Int16Array:true,Int32Array:true,Int8Array:true,Uint16Array:true,Uint32Array:true,Uint8ClampedArray:true,CanvasPixelArray:true,Uint8Array:false})
A.C.$nativeSuperclassTag="ArrayBufferView"
A.bQ.$nativeSuperclassTag="ArrayBufferView"
A.bR.$nativeSuperclassTag="ArrayBufferView"
A.bv.$nativeSuperclassTag="ArrayBufferView"
A.bS.$nativeSuperclassTag="ArrayBufferView"
A.bT.$nativeSuperclassTag="ArrayBufferView"
A.bw.$nativeSuperclassTag="ArrayBufferView"})()
Function.prototype.$1=function(a){return this(a)}
Function.prototype.$0=function(){return this()}
Function.prototype.$2=function(a,b){return this(a,b)}
Function.prototype.$3=function(a,b,c){return this(a,b,c)}
Function.prototype.$4=function(a,b,c,d){return this(a,b,c,d)}
Function.prototype.$1$1=function(a){return this(a)}
convertAllToFastObject(w)
convertToFastObject($);(function(a){if(typeof document==="undefined"){a(null)
return}if(typeof document.currentScript!="undefined"){a(document.currentScript)
return}var s=document.scripts
function onLoad(b){for(var q=0;q<s.length;++q){s[q].removeEventListener("load",onLoad,false)}a(b.target)}for(var r=0;r<s.length;++r){s[r].addEventListener("load",onLoad,false)}})(function(a){v.currentScript=a
var s=A.eP
if(typeof dartMainRunner==="function"){dartMainRunner(s,[])}else{s([])}})})()
//# sourceMappingURL=e2ee.worker.dart.js.map
