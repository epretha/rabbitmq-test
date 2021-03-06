%% The contents of this file are subject to the Mozilla Public License
%% Version 1.1 (the "License"); you may not use this file except in
%% compliance with the License. You may obtain a copy of the License at
%% http://www.mozilla.org/MPL/
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
%% License for the specific language governing rights and limitations
%% under the License.
%%
%% The Original Code is RabbitMQ.
%%
%% The Initial Developer of the Original Code is GoPivotal, Inc.
%% Copyright (c) 2011-2015 Pivotal Software, Inc.  All rights reserved.
%%

-module(password_hashing_tests).

-include("rabbit.hrl").

-export([test_password_hashing/0, test_change_password/0]).

test_password_hashing() ->
    rabbit_password_hashing_sha256 = rabbit_password:hashing_mod(),
    application:set_env(rabbit, password_hashing_module, rabbit_password_hashing_md5),
    rabbit_password_hashing_md5    = rabbit_password:hashing_mod(),
    application:set_env(rabbit, password_hashing_module, rabbit_password_hashing_sha256),
    rabbit_password_hashing_sha256 = rabbit_password:hashing_mod(),

    rabbit_password_hashing_sha256 = rabbit_password:hashing_mod(rabbit_password_hashing_sha256),
    rabbit_password_hashing_md5    = rabbit_password:hashing_mod(rabbit_password_hashing_md5),
    rabbit_password_hashing_md5    = rabbit_password:hashing_mod(undefined),

    rabbit_password_hashing_md5    =
        rabbit_auth_backend_internal:hashing_module_for_user(
          #internal_user{}),
    rabbit_password_hashing_md5    =
        rabbit_auth_backend_internal:hashing_module_for_user(
          #internal_user{
             hashing_algorithm = undefined
            }),
    rabbit_password_hashing_md5    =
        rabbit_auth_backend_internal:hashing_module_for_user(
          #internal_user{
             hashing_algorithm = rabbit_password_hashing_md5
            }),

    rabbit_password_hashing_sha256 =
        rabbit_auth_backend_internal:hashing_module_for_user(
          #internal_user{
             hashing_algorithm = rabbit_password_hashing_sha256
            }),

    passed.

test_change_password() ->
    UserName = <<"test_user">>,
    Password = <<"test_password">>,
    case rabbit_auth_backend_internal:lookup_user(UserName) of
        {ok, _} -> rabbit_auth_backend_internal:delete_user(UserName);
        _       -> ok
    end,
    ok = application:set_env(rabbit, password_hashing_module, rabbit_password_hashing_md5),
    ok = rabbit_auth_backend_internal:add_user(UserName, Password),
    {ok, #auth_user{username = UserName}} =
        rabbit_auth_backend_internal:user_login_authentication(
            UserName, [{password, Password}]),
    ok = application:set_env(rabbit, password_hashing_module, rabbit_password_hashing_sha256),
    {ok, #auth_user{username = UserName}} =
        rabbit_auth_backend_internal:user_login_authentication(
            UserName, [{password, Password}]),

    NewPassword = <<"test_password1">>,
    ok = rabbit_auth_backend_internal:change_password(UserName, NewPassword),
    {ok, #auth_user{username = UserName}} =
        rabbit_auth_backend_internal:user_login_authentication(
            UserName, [{password, NewPassword}]),

    {refused, _, [UserName]} =
        rabbit_auth_backend_internal:user_login_authentication(
            UserName, [{password, Password}]),
    passed.
