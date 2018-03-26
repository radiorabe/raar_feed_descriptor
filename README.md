# raar_feed_descriptor

Store descriptions for certain shows from the rabe.ch website feed into archiv.rabe.ch.

See configuration in `config/settings.example.yml`. Copy this file to `config/settings.yml`, complete it and run `raar_feed_descriptor.rb`.


## Deployment

## Initial

* Install the Ruby 2.2 Software Collection.
* Create a user on the server:
  * `useradd --home-dir /opt/raar-feed-descriptor --create-home --user-group raar-feed-descriptor`
  * `usermod -a -G raar-feed-descriptor <your-ssh-user>`
  * `chmod g+w /opt/raar-feed-descriptor`
  * Add your SSH public key to `/opt/raar-feed-descriptor/.ssh/authorized_keys`.
* Perform the every time steps.
* Copy both systemd files from `config` to `/etc/systemd/system/`.
* Enable and start the systemd timer: `systemctl enable --now raar-feed-descriptor.timer`

## Every time

* Prepare the dependencies on your local machine: `bundle package --all-platforms`
* SCP all files to `raar-feed-descriptor@server:/opt/raar-feed-descriptor/`.
* Install the dependencies on the server (as `raar-feed-descriptor` in `/opt/raar-feed-descriptor`):
  `source /opt/rh/rh-ruby22/enable && bundle install --deployment --quiet --local`


## License

raar_feed_descriptor is released under the terms of the GNU Affero General Public License.
Copyright 2018 Radio RaBe.
See `LICENSE` for further information.
