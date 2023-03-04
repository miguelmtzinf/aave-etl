{{ config(materialized='table') }}

with stables as (
select
  block_day
  , display_chain
  , display_market
  , sum(value_usd) as stablecoin_value_usd
-- from datamart.all_treasury_balances
from {{ref('all_treasury_balances')}}
where stable_class = 'stablecoin'
group by block_day, display_chain, display_market
)
, totals as (
select
  block_day
  , display_chain
  , display_market
  , sum(value_usd) as value_usd
-- from datamart.all_treasury_balances
from {{ref('all_treasury_balances')}}
group by block_day, display_chain, display_market
)
, ex_aave as (
select
  block_day
  , display_chain
  , display_market
  , sum(value_usd) as ex_aave_value_usd
-- from datamart.all_treasury_balances
from {{ref('all_treasury_balances')}}
where symbol != 'AAVE'
group by block_day, display_chain, display_market
)
select
  t.block_day
  , t.display_chain
  , t.display_market
  , coalesce(t.value_usd, 0) as value_usd
  , coalesce(s.stablecoin_value_usd, 0) as stablecoin_value_usd
  , coalesce(a.ex_aave_value_usd, 0) as ex_aave_value_usd
from totals t 
  left join stables s on (t.block_day = s.block_day and t.display_chain = s.display_chain and t.display_market = s.display_market)
  left join ex_aave a on (t.block_day = a.block_day and t.display_chain = a.display_chain and t.display_market = a.display_market)
order by block_day, display_chain, display_market